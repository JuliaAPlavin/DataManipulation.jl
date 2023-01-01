module ArraysExtra

using Accessors
using InverseFunctions
using StructArrays
using Dictionaries
using Reexport
@reexport using Skipper
@reexport using FlexiGroups
@reexport using FilterMaps

export
    @S_str,
    mutate, mutateview,
    filterview,
    mapview, maprange,
    sortview, uniqueview,
    sentinelview,
    materialize_views


include("symbols.jl")
include("views.jl")
include("mutate.jl")
include("filterview.jl")
include("mapview.jl")
include("uniqueview.jl")
include("sentinelview.jl")



materialize_views(s::Skipper.Skip) = collect(s)
Base.getproperty(A::Skipper.Skip, p::Symbol) = mapview(Accessors.PropertyLens(p), A)
Base.getproperty(A::Skipper.Skip, p) = mapview(Accessors.PropertyLens(p), A)



_eltype(::T) where {T} = _eltype(T)
function _eltype(::Type{T}) where {T}
    ETb = eltype(T)
    ETb != Any && return ETb
    # Base.eltype returns Any for mapped/flattened/... iterators
    # here we attempt to infer a tighter type
    ET = Core.Compiler.return_type(first, Tuple{T})
    ET === Union{} ? Any : ET
end

end
