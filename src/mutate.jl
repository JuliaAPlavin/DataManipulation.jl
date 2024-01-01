"""    mapset(X; prop=f, ...)

Set values of `x.prop` to `f(x)` for all `x` elements of `X`. Common usage is for modifying table columns.

Equivalent to `map(x -> @set(x.prop = f(x)), X)`, but supports multiple properties.

When `X` is a `StructArray`: uses an optimized approach, keeping all other component untouched. """
mapset(A; kwargs...) = _mapmerge(A, map, _merge_set; kwargs...)

"""    mapinsert(X; prop=f, ...)

Insert `x.prop` with the value `f(x)` into all `x` elements of `X`. Common usage is for adding table columns.

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
