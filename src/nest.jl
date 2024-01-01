"""
    nest(::NamedTuple, [sr"regex" [=> (ss"sub", ...)], ...])
    nest(::StructArray, [sr"regex" [=> (ss"sub", ...)], ...])

Put a subset of properties into a nested object of the same kind (eg a nested `NamedTuple``).

Properties to nest are selected in compile time by a regular expression. Their resulting names are extracted from the regex groups, or specified explicitly by substitution strings.

# Examples

```julia
julia> nest((a_x=1, a_y="2", a_z_z=3, b=:z), sr"(a)_(\\w+)" ))
(a=(x=1, y="2", z_z=3), b=:z)

julia> nest( (a_x=1, a_y="2", a_z_z=3, b=:z), sr"(a)_(\\w+)" => (ss"x\\1", ss"val", ss"\\2") ))
(xa=(val=(x=1, y="2", z_z=3),), b=:z)
```
"""
function nest end

@generated function nest(x::NamedTuple{KS}, ::StaticRegex{SR}) where {KS, SR}
    regex = _anchored_regex(SR)
    _nest_code(KS, regex) do m
        @p m |> pairs |> collect |> filter(!isnothing(last(_))) |> sort |> map(last) |> map(Symbol)
    end
end

@generated function nest(x::NamedTuple{KS}, ::Pair{StaticRegex{SR}, SS}) where {KS, SR, SS <: Tuple}
    regex = _anchored_regex(SR)
    subs = map(unstatic, SS.types)
    _nest_code(KS, regex) do m
        @p subs |> map(sub -> replace(m.match, regex => sub)) |> map(Symbol)
    end
end

nest(x, rs...) =
    foldl(rs; init=x) do x, r
        nest(x, r)
    end

_anchored_regex(SR::Symbol) = Regex(string(SR), Base.DEFAULT_COMPILER_OPTS | Base.PCRE.ANCHORED | Base.PCRE.ENDANCHORED, Base.DEFAULT_MATCH_OPTS)

function _nest_code(func, KS, regex)
    paths = map(KS) do k
        ks = string(k)
        m = match(regex, ks)
        isnothing(m) && return [k]
        @assert m.match == ks
        return func(m)
    end
    allunique(paths) || error("Target paths not unique: $paths")
    npairs = paths_to_nested_pairs(paths, KS)
    nested_pairs_to_ntexpr(npairs)
end

nested_pairs_to_ntexpr(npairs::Symbol) = :(x.$npairs)
function nested_pairs_to_ntexpr(npairs)
    :(
        NamedTuple{$(npairs .|> first |> Tuple)}((
            $((npairs .|> last .|> nested_pairs_to_ntexpr)...),
        ))
    )
end

function paths_to_nested_pairs(paths, values)
    if length(paths) == 1 && only(paths) == []
        return only(values)
    end
    @assert !any(isempty, paths)
    @p let
        zip(paths, values)
        group(_[1][1])
        pairs
        collect
        map() do (k, gr)
            k => paths_to_nested_pairs(map(p -> p[2:end], first.(gr)), last.(gr))
        end
    end
end


# struct KeepSame end

# @generated function _unnest(nt::NamedTuple{KS, TS}, ::Val{KEYS}=Val(nothing), ::Val{TARGET}=Val(KeepSame())) where {KS, TS, KEYS, TARGET}
#     types = fieldtypes(TS)
#     assigns = mapreduce(vcat, KS, types) do k, T
#         if !isnothing(KEYS) && k ∈ KEYS && !(T <: NamedTuple)
#             error("Cannot unnest field $k::$T")
#         end

#         if (isnothing(KEYS) || k ∈ KEYS) && T <: NamedTuple
#             ks = fieldnames(T)
#             tgt_k = TARGET isa KeepSame ? k : TARGET
#             ks_new = map(ks) do k_
#                 isnothing(tgt_k) ? k_ : Symbol(tgt_k, :_, k_)
#             end
#             map(ks, ks_new) do k_, k_n
#                 :( $k_n = nt.$k.$k_ )
#             end |> collect
#         else
#             :( $k = nt.$k )
#         end
#     end
#     :( ($(assigns...),) )
# end

# @inline unnest(nt::NamedTuple) = _unnest(nt)
# @inline unnest(nt::NamedTuple, k::Symbol) = _unnest(nt, Val((k,)))
# @inline unnest(nt::NamedTuple, kv::Pair{Symbol, <:Union{Symbol, Nothing}}) = _unnest(nt, Val((first(kv),)), Val(last(kv)))
# @inline unnest(nt::NamedTuple, ks::Tuple{Vararg{Symbol}}) = _unnest(nt, Val(ks))






# vcat_data(ds...; kwargs...) = reduce(vcat_data, ds; kwargs...)
# function Base.reduce(::typeof(vcat_data), ds; source=nothing)
#     isnothing(source) ?
#         reduce(vcat, ds) :
#         mapmany(((k, d),) -> d, ((k, d), x) -> insert(x, source, k), zip(keys(ds), values(ds)))
# end
