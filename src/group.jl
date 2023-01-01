function groupfind(f, X; kwargs...)
    (; dct, starts, rperm) = _group_core(f, X, keys(X); kwargs...)
    mapvalues(dct) do gid
        @view rperm[starts[gid + 1]:-1:1 + starts[gid]]
    end
end

function groupview(f, X; kwargs...)
    (; dct, starts, rperm) = _group_core(f, X, keys(X); kwargs...)
    mapvalues(dct) do gid
        ix = @view rperm[starts[gid + 1]:-1:1 + starts[gid]]
        @view X[ix]
    end
end

function group(f, X; kwargs...)
    (; dct, starts, rperm) = _group_core(f, X, values(X); kwargs...)
    mapvalues(dct) do gid
        @view rperm[starts[gid + 1]:-1:1 + starts[gid]]
    end
end

function groupmap(f, ::typeof(length), X; kwargs...)
    (; dct, starts, rperm) = _group_core(f, X, similar(X, Nothing); kwargs...)
    mapvalues(dct) do gid
        starts[gid + 1] - starts[gid]
    end
end

function groupmap(f, ::typeof(first), X; kwargs...)
    (; dct, starts, rperm) = _group_core(f, X, keys(X); kwargs...)
    mapvalues(dct) do gid
        ix = rperm[starts[gid + 1]]
        X[ix]
    end
end

function groupmap(f, ::typeof(last), X; kwargs...)
    (; dct, starts, rperm) = _group_core(f, X, keys(X); kwargs...)
    mapvalues(dct) do gid
        ix = rperm[1 + starts[gid]]
        X[ix]
    end
end

function groupmap(f, ::typeof(only), X; kwargs...)
    (; dct, starts, rperm) = _group_core(f, X, keys(X); kwargs...)
    mapvalues(dct) do gid
        starts[gid + 1] == starts[gid] + 1 || throw(ArgumentError("groupmap(only, X) requires that each group has exactly one element"))
        ix = rperm[starts[gid + 1]]
        X[ix]
    end
end

_group_core(f, X, vals; dicttype=Dictionary) = _group_core(f, X, vals, dicttype)

function _group_core(f, X::AbstractArray, vals::AbstractArray, ::Type{DT}) where {DT}
    ngroups = 0
    groups = similar(X, Int)
    dct = DT{Core.Compiler.return_type(f, Tuple{_valtype(X)}), Int}()
    @inbounds for (i, x) in pairs(X)
        groups[i] = gid = get!(dct, f(x), ngroups + 1)
        if gid == ngroups + 1
            ngroups += 1
        end
    end

    starts = zeros(Int, ngroups)
    @inbounds for gid in groups
        starts[gid] += 1
    end
    cumsum!(starts, starts)
    push!(starts, length(groups))

    rperm = similar(vals, Base.OneTo(length(vals)))
    # rperm = Vector{_eltype(vals)}(undef, length(X))
    @inbounds for (v, gid) in zip(vals, groups)
        rperm[starts[gid]] = v
        starts[gid] -= 1
    end

    # dct: key -> group_id
    # rperm[starts[group_id + 1]:-1:1 + starts[group_id]] = group_values

    return (; dct, starts, rperm)
end


function _group_core(f, X, vals, ::Type{DT}) where {DT}
    ngroups = 0
    groups = Int[]
    dct = DT{Core.Compiler.return_type(f, Tuple{_valtype(X)}), Int}()
    @inbounds for x in X
        gid = get!(dct, f(x), ngroups + 1)
        push!(groups, gid)
        if gid == ngroups + 1
            ngroups += 1
        end
    end

    starts = zeros(Int, ngroups)
    @inbounds for gid in groups
        starts[gid] += 1
    end
    cumsum!(starts, starts)
    push!(starts, length(groups))

    rperm = Vector{_eltype(vals)}(undef, length(groups))
    @inbounds for (v, gid) in zip(vals, groups)
        rperm[starts[gid]] = v
        starts[gid] -= 1
    end

    # dct: key -> group_id
    # rperm[starts[group_id + 1]:-1:1 + starts[group_id]] = group_values

    return (; dct, starts, rperm)
end


mapvalues(f, dict::AbstractDictionary) = map(f, dict)

function mapvalues(f, dict::Dict)
    V = Core.Compiler.return_type(f, Tuple{valtype(dict)})
    vals = dict.vals
    newvals = similar(vals, V)
    @inbounds for i in dict.idxfloor:lastindex(vals)
        if Base.isslotfilled(dict, i)
            newvals[i] = f(vals[i])
        end
    end
    _setproperties(dict, (;vals=newvals))
end

function _setproperties(d::Dict, patch::NamedTuple{(:vals,)})
    K = keytype(d)
    V = eltype(patch.vals)
    @assert length(d.keys) == length(patch.vals)
    Dict{K,V}(copy(d.slots), copy(d.keys), patch.vals, d.ndel, d.count, d.age, d.idxfloor, d.maxprobe)
end
