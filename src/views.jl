""""    materialize_views(X)

Materialize views arbitrarily nested in dictionaries and `StructArray`s. """
materialize_views(A::Union{AbstractArray,AbstractDict}) = @modify(materialize_views, values(A)[∗])
materialize_views(A) = A

"""    collectview(X)

Turn the input into an `AbstractArray`, like `collect` but doesn't copy.
Mostly useful for general handling of arrays and dictionaries. """
collectview(A::AbstractArray) = A
