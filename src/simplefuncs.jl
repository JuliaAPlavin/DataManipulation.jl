"""    findonly(pred, X)

Like `findfirst`, but ensures that exactly a single match is present. """
function findonly(pred, A)
    ix = findfirst(pred, A)
    isnothing(ix) && throw(ArgumentError("no element satisfies the predicate"))
    isnothing(findnext(pred, A, nextind(A, ix))) || throw(ArgumentError("multiple elements satisfy the predicate"))
    return ix
end

"""    filterfirst(pred, X)

More efficient `first(filter(f, X))`. """
filterfirst(pred, A) = @p A |> Iterators.filter(pred) |> first

"""    filteronly(pred, X)

More efficient `only(filter(f, X))`. """
filteronly(pred, A) = @p A |> Iterators.filter(pred) |> only

"""    uniqueonly(pred, X)

More efficient `only(unique([f], X))`. """
uniqueonly(A) = uniqueonly(identity, A)
function uniqueonly(f, A)
    allequal(mapview(f, A)) || throw(ArgumentError("multiple unique values"))
    return first(A)
end
