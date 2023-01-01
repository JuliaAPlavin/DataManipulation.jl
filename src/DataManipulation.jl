module DataManipulation

using StructArrays
using Dictionaries
using InverseFunctions
using Accessors
using Reexport
@reexport using DataPipes
@reexport using Skipper
@reexport using SentinelViews
@reexport using FlexiGroups
@reexport using FlexiMaps

export
    @S_str,
    findonly, filterfirst, filteronly, uniqueonly,
    mapset, mapinsert, mapinsert⁻, mapsetview, mapinsertview,
    filterview,
    sortview, uniqueview,
    materialize_views, collectview


include("symbols.jl")
include("simplefuncs.jl")
include("views.jl")
include("mutate.jl")
include("filterview.jl")
include("uniqueview.jl")
include("discreterange.jl")


# some interactions: include type piracy, but this cannot be put in upstream packages
materialize_views(s::Skipper.Skip) = collect(s)
Base.getproperty(A::Skipper.Skip, p::Symbol) = mapview(FlexiMaps.Accessors.PropertyLens(p), A)
Base.getproperty(A::Skipper.Skip, p) = mapview(FlexiMaps.Accessors.PropertyLens(p), A)

end
