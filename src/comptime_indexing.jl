Base.getindex(nt::NamedTuple, p::Union{StaticRegex, Pair{<:StaticRegex}}, args...) = merge(nt[p], nt[args...])

@generated function Base.getindex(nt::NamedTuple{NS}, SR::StaticRegex) where {NS}
    regex = unstatic(SR)
    ns = filter(n -> occursin(regex, String(n)), NS)
    return :( nt[$ns] )
end

@generated function Base.getindex(nt::NamedTuple{NS}, ::Pair{SR, SS}) where {NS, SR<:StaticRegex, SS<:StaticSubstitution}
    regex = unstatic(SR)
    subs = unstatic(SS)
    ns = filter(n -> occursin(regex, String(n)), NS)
    nss = map(n -> replace(String(n), regex => subs) |> Symbol, ns)
    return :( NamedTuple{$nss}(($([:(nt.$ns) for ns in ns]...),)) )
end

# cannot avoid "method too new" error:
# @generated function Base.getindex(nt::NamedTuple{NS}, ::Pair{StaticRegex{rs}, F}) where {NS, rs, F <: Function}
#     regex = Regex(String(rs))
#     ns = filter(n -> occursin(regex, String(n)), NS)
#     nss = map(n -> replace(String(n), regex => s -> Base.invokelatest(F.instance, s)) |> Symbol, ns)
#     return :( NamedTuple{$nss}(($([:(nt.$ns) for ns in ns]...),)) )
# end

@generated function Base.setindex(nt::NamedTuple{NS}, val::NamedTuple{VNS}, SR::StaticRegex) where {NS, VNS}
    regex = unstatic(SR)
    ns = filter(n -> occursin(regex, String(n)), NS)
    @assert VNS == ns
    return :(merge(nt, val))
end


Accessors.delete(nt::NamedTuple, o::IndexLens{<:Tuple{StaticRegex, Vararg{Any}}}) = _delete(nt, o.indices...)

_delete(nt::NamedTuple, p::Union{StaticRegex, Pair{<:StaticRegex}}, args...) = _delete(_delete(nt, p), args...)

@generated function _delete(nt::NamedTuple{NS}, SR::StaticRegex) where {NS}
    regex = unstatic(SR)
    ns = filter(n -> !occursin(regex, String(n)), NS)
    return :( nt[$ns] )
end
