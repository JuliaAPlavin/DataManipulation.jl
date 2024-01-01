module DataManipulation

using Reexport
using InverseFunctions
@reexport using Accessors
using AccessorsExtra  # for values()
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
    nest, @sr_str, @ss_str,
    shift_range,
    rev


include("symbols.jl")
include("simplefuncs.jl")
include("views.jl")
include("mutate.jl")
include("uniqueview.jl")
include("discreterange.jl")
include("typeval_strings.jl")
include("comptime_indexing.jl")
include("nest.jl")


"""    shift_range(x, a..b => A..B; clamp=false)

Linearly transform `x` from range `a..b` to `A..B`.
"""
function shift_range end


struct rev{T}
    val::T
end

Base.isless(a::rev, b::rev) = isless(b.val, a.val)


# some interactions: include type piracy, but this cannot be put in upstream packages
materialize_views(s::Skipper.Skip) = collect(s)
Base.getproperty(A::Skipper.Skip, p::Symbol) = mapview(FlexiMaps.Accessors.PropertyLens(p), A)
Base.getproperty(A::Skipper.Skip, p) = mapview(FlexiMaps.Accessors.PropertyLens(p), A)

end
