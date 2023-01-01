function groupfind(f, X)
    (; dct, starts, rperm) = _group_core(f, X, keys(X))
    @modify(dct |> Values()) do gid
        @view rperm[starts[gid + 1]:-1:1 + starts[gid]]
    end
end

function groupview(f, X)
    (; dct, starts, rperm) = _group_core(f, X, keys(X))
    @modify(dct |> Values()) do gid
        ix = @view rperm[starts[gid + 1]:-1:1 + starts[gid]]
        @view X[ix]
    end
end

function group(f, X)
    (; dct, starts, rperm) = _group_core(f, X, values(X))
    @modify(dct |> Values()) do gid
        @view rperm[starts[gid + 1]:-1:1 + starts[gid]]
    end
end

function _group_core(f, X, vals)
    ngroups = 0
    groups = similar(X, Int)
    dct = Dict{Core.Compiler.return_type(f, Tuple{valtype(X)}), Int}()
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
    # rperm = Vector{eltype(vals)}(undef, length(X))
    @inbounds for (v, gid) in zip(vals, groups)
        rperm[starts[gid]] = v
        starts[gid] -= 1
    end

    # dct: key -> group_id
    # rperm[starts[group_id + 1]:-1:1 + starts[group_id]] = group_values

    return (; dct, starts, rperm)
end
