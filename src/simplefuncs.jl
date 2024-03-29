"""    findonly(pred, X)

Like `findfirst(pred, X)`, but ensures that exactly a single match is present. """
function findonly(pred::F, A) where {F}
    ix = findfirst(pred, A)
    isnothing(ix) && throw(ArgumentError("no element satisfies the predicate"))
    isnothing(findnext(pred, A, nextind(A, ix))) || throw(ArgumentError("multiple elements satisfy the predicate"))
    return ix
end

findonly(pred::F, A::NamedTuple{KS}) where {F,KS} = KS[findonly(pred, Tuple(A))]


"""    filterfirst(pred, X)

More efficient `first(filter(pred, X))`. """
filterfirst(pred::F, A) where {F} = @p A |> Iterators.filter(pred) |> first

"""    filteronly(pred, X)

More efficient `only(filter(pred, X))`. """
filteronly(pred::F, A) where {F} = @p A |> Iterators.filter(pred) |> only

"""    uniqueonly([pred], X)

More efficient `only(unique([pred], X))`. """
function uniqueonly end

uniqueonly(A) = uniqueonly(identity, A)
function uniqueonly(f::F, A) where {F}
    allequal(mapview(f, A)) || throw(ArgumentError("multiple unique values"))
    return first(A)
end


Accessors.set(obj, ::typeof(uniqueonly), v) = set(obj, Elements(), v)
Accessors.set(obj, o::Base.Fix1{typeof(filterfirst)}, v) = @set obj[findfirst(o.x, obj)] = v
Accessors.set(obj, o::Base.Fix1{typeof(filteronly)}, v) = @set obj[findonly(o.x, obj)] = v

Accessors.delete(obj, o::Base.Fix1{typeof(filterfirst)}) = @delete obj[findfirst(o.x, obj)]
Accessors.delete(obj, o::Base.Fix1{typeof(filteronly)}) = @delete obj[findonly(o.x, obj)]
