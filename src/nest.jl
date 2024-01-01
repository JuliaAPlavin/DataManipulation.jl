# struct Str{S} end
struct StrRe{S} end
struct StrSub{S} end

# macro c_str(x)
# 	:($Str{Symbol($x)}())
# end
macro cr_str(x)
	:($StrRe{Symbol($x)}())
end
macro cs_str(x)
	:($StrSub{Symbol($x)}())
end


@generated function nest(x::NamedTuple{KS}, ::StrRe{SR}) where {KS, SR}
    regex = _anchored_regex(SR)
    _nest_code(KS, regex) do m
        @p m |> pairs |> collect |> filter(!isnothing(last(_))) |> sort |> map(last) |> map(Symbol)
    end
end

@generated function nest(x::NamedTuple{KS}, ::Pair{StrRe{SR}, SS}) where {KS, SR, SS <: Tuple}
    regex = _anchored_regex(SR)
    extract_sub(::Type{StrSub{S}}) where {S} = SubstitutionString(string(S))
    subs = map(extract_sub, SS.types)
    _nest_code(KS, regex) do m
        @p subs |> map(sub -> replace(m.match, regex => sub)) |> map(Symbol)
    end
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
