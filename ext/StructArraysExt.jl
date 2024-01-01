module StructArraysExt
using StructArrays
using DataManipulation.Accessors
import DataManipulation: nest, materialize_views, StaticRegex


Base.getindex(A::StructArray, p::Union{StaticRegex, Pair{<:StaticRegex}}, args...) =
    @modify(StructArrays.components(A)) do nt
        nt[p, args...]
    end

Accessors.delete(A::StructArray, o::IndexLens{<:Tuple{StaticRegex, Vararg{Any}}}) = 
    @modify(StructArrays.components(A)) do nt
        delete(nt, o)
    end


function nest(x::StructArray, args...)
    comps = StructArrays.components(x)
    comps_n = nest(comps, args...)
    _sa_from_comps_nested(comps_n)
end

_sa_from_comps_nested(X::AbstractArray) = X
_sa_from_comps_nested(X::Union{Tuple,NamedTuple}) = StructArray(map(_sa_from_comps_nested, X))


materialize_views(A::StructArray) = StructArray(map(materialize_views, StructArrays.components(A)))

end
