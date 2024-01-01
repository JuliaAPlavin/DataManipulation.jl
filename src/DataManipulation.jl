module DataManipulation

using Reexport
using InverseFunctions
@reexport using Accessors
@reexport using DataPipes
@reexport using Skipper
@reexport using FlexiGroups
@reexport using FlexiMaps

export
    @S_str,
    findonly, filterfirst, filteronly, uniqueonly,
    mapset, mapinsert, mapinsert⁻, mapsetview, mapinsertview,
    sortview, uniqueview,
    materialize_views, collectview,
    nest, @cr_str, @cs_str,
    shift_range


include("symbols.jl")
include("simplefuncs.jl")
include("views.jl")
include("nest.jl")
include("mutate.jl")
include("uniqueview.jl")
include("discreterange.jl")


"""    shift_range(x, a..b => A..B; clamp=false)

Linearly transform `x` from range `a..b` to `A..B`.
"""
function shift_range end


# some interactions: include type piracy, but this cannot be put in upstream packages
materialize_views(s::Skipper.Skip) = collect(s)
Base.getproperty(A::Skipper.Skip, p::Symbol) = mapview(FlexiMaps.Accessors.PropertyLens(p), A)
Base.getproperty(A::Skipper.Skip, p) = mapview(FlexiMaps.Accessors.PropertyLens(p), A)

end
