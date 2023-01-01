module ArraysExtra

using StructArrays

export @S_str, filtermap, flatmap, flatmap!, flatten, flatten!, mutate

include("symbols.jl")
include("filtermap.jl")
include("flatmap.jl")
include("mutate.jl")

end
