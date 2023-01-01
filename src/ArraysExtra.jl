module ArraysExtra

using Accessors
using InverseFunctions
using StructArrays
using Dictionaries
# using Reexport
# @reexport using Skipper
# @reexport using FlexiGroups

export
    @S_str,
    filtermap,
    flatmap, flatmap!, flatten, flatten!,
    mutate, mutateview,
    filterview,
    mapview, maprange,
    findonly,
    sortview, uniqueview,
    sentinelview,
    materialize_views


include("symbols.jl")
include("views.jl")
include("filtermap.jl")
include("flatmap.jl")
include("mutate.jl")
include("filterview.jl")
include("mapview.jl")
include("uniqueview.jl")
include("sentinelview.jl")


function findonly(pred, A)
    ix = findfirst(pred, A)
    isnothing(ix) && throw(ArgumentError("no element satisfies the predicate"))
    isnothing(findnext(pred, A, nextind(A, ix))) || throw(ArgumentError("more than one element satisfies the predicate"))
    return ix
end


_eltype(::T) where {T} = _eltype(T)
function _eltype(::Type{T}) where {T}
    ETb = eltype(T)
    ETb != Any && return ETb
    # Base.eltype returns Any for mapped/flattened/... iterators
    # here we attempt to infer a tighter type
    ET = Core.Compiler.return_type(first, Tuple{T})
    ET === Union{} ? Any : ET
end

_valtype(X) = _eltype(values(X))

end
