"""    mapset(X; prop=f, ...)

Set values of `x.prop` to `f(x)` for all elements. Common usage is for modifying table columns.

Equivalent to `map(x -> @set(x.prop = f(x)), X)`, but supports multiple properties.

When `X` is a `StructArray`: uses an optimized approach, keeping all other component untouched. """
mapset(A; kwargs...) = _mapmerge(A, map, _merge_set; kwargs...)

"""    mapview(X; prop=f, ...)

Insert `x.prop` into each element with the value `f(x)`. Common usage is for adding table columns.

Equivalent to `map(x -> @insert(x.prop = f(x)), X)`, but supports multiple properties.

When `X` is a `StructArray`: uses an optimized approach, keeping all other component untouched. """
mapinsert(A; kwargs...) = _mapmerge(A, map, _merge_insert; kwargs...)

"""    mapsetview(X; prop=f, ...)

Like `mapset`, but returns a view instead of a copy.

When `X` is a `StructArray`: uses an optimized approach, keeping all other component untouched. """
mapsetview(A; kwargs...) = _mapmerge(A, mapview, _merge_set; kwargs...)

"""    mapinsertview(X; prop=f, ...)

Like `mapinsert`, but returns a view instead of a copy.

When `X` is a `StructArray`: uses an optimized approach, keeping all other component untouched. """
mapinsertview(A; kwargs...) = _mapmerge(A, mapview, _merge_insert; kwargs...)

_mapmerge(A, mapf, mergef; kwargs...) = mapf(a -> mergef(a, map(fx -> fx(a), values(kwargs))), A)

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

function mapinsert⁻(A; kwargs...)
    deloptics = map(values(kwargs)) do o
        Accessors.deopcompose(o) |> first
    end
    @p map(A) do __
        _merge_insert(__, map(fx -> fx(__), values(kwargs)))
        reduce((acc, o) -> delete(acc, o), deloptics; init=__)
    end
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
