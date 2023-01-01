module ArraysExtra

using AccessorsExtra
using InverseFunctions
using StructArrays

export @S_str, filtermap, flatmap, flatmap!, flatten, flatten!, mutate, group, groupfind, groupview, groupmap, filterview, skip, skipnan, mapview

include("symbols.jl")
include("filtermap.jl")
include("flatmap.jl")
include("mutate.jl")
include("group.jl")
include("filterview.jl")
include("skip.jl")
include("mapview.jl")

end
