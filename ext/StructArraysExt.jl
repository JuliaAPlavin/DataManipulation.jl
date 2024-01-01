module StructArraysExt
using StructArrays
using DataManipulation.Accessors
using DataManipulation.DataPipes
import DataManipulation: _mapmerge, _merge_insert, mapinsert⁻, nest, materialize_views, StrRe

function _mapmerge(A::StructArray{<:NamedTuple}, mapf, mergef; kwargs...)
    new_comps = map(values(kwargs)) do fx
        mapf(fx, A)
    end
    return StructArray(mergef(StructArrays.components(A), new_comps))
end

function mapinsert⁻(A::StructArray; kwargs...)
    deloptics = map(values(kwargs)) do o
        Accessors.deopcompose(o) |> first
    end
    @p let
        StructArrays.components(A)
        _merge_insert(__, map(fx -> map(fx, A), values(kwargs)))
        reduce((acc, o) -> delete(acc, o), deloptics; init=__)
        StructArray()
    end
end


Base.getindex(A::StructArray, p::Union{StrRe, Pair{<:StrRe}}, args...) =
    @modify(StructArrays.components(A)) do nt
        nt[p, args...]
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
