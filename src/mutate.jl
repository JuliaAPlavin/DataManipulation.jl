mapset(A; kwargs...) = _mapmerge(A, map, _merge_set; kwargs...)
mapinsert(A; kwargs...) = _mapmerge(A, mapview, _merge_insert; kwargs...)
mapsetview(A; kwargs...) = _mapviewmerge(A, map, _merge_set; kwargs...)
mapinsertview(A; kwargs...) = _mapviewmerge(A, mapview, _merge_insert; kwargs...)

_mapmerge(A, mapf, mergef; kwargs...) = mapf(a -> mergef(a, map(fx -> fx(a), values(kwargs))), A)
_mapviewmerge(A, mapf, mergef; kwargs...) = mapf(a -> mergef(a, map(fx -> fx(a), values(kwargs))), A)

function _mapmerge(A::StructArray{<:NamedTuple}, mapf, mergef; kwargs...)
    new_comps = map(values(kwargs)) do fx
        mapf(fx, A)
    end
    return StructArray(mergef(StructArrays.components(A), new_comps))
end

_merge_set(a::NamedTuple{KSA}, b::NamedTuple{KSB}) where {KSA, KSB} = (@assert KSB ⊆ KSA; merge(a, b))
_merge_insert(a::NamedTuple{KSA}, b::NamedTuple{KSB}) where {KSA, KSB} = (@assert isdisjoint(KSB, KSA); merge(a, b))
_merge_set(a, b) = merge(a, b)
_merge_insert(a, b) = merge(a, b)
