module ArraysExtra

using AccessorsExtra
using InverseFunctions
using StructArrays

export
    @S_str,
    filtermap,
    flatmap, flatmap!, flatten, flatten!,
    mutate,
    group, groupfind, groupview, groupmap,
    filterview,
    skip, skipnan,
    mapview,
    findonly


include("symbols.jl")
include("filtermap.jl")
include("flatmap.jl")
include("mutate.jl")
include("group.jl")
include("filterview.jl")
include("skip.jl")
include("mapview.jl")


function findonly(pred, A)
    ix = findfirst(pred, A)
    isnothing(ix) && throw(ArgumentError("no element satisfies the predicate"))
    isnothing(findnext(pred, A, nextind(A, ix))) || throw(ArgumentError("more than one element satisfies the predicate"))
    return ix
end

end
