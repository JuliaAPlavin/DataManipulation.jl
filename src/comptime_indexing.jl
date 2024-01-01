@generated function Base.getindex(nt::NamedTuple, p::Union{StaticRegex, Pair{<:StaticRegex}}, args...)
    :( merge(nt[p], nt[args...]))
end

@generated function Base.getindex(nt::NamedTuple{NS}, ::StaticRegex{SR}) where {NS, SR}
    regex = Regex(String(SR))
    ns = filter(n -> occursin(regex, String(n)), NS)
    return :( nt[$ns] )
end

@generated function Base.getindex(nt::NamedTuple{NS}, ::Pair{StaticRegex{SR}, StaticSubstitution{SS}}) where {NS, SR, SS}
    regex = Regex(String(SR))
    subs = SubstitutionString(String(SS))
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
