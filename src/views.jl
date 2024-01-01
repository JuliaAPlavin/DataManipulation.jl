""""    materialize_views(X)

Materialize views arbitrarily nested in dictionaries and `StructArray`s. """
materialize_views(A::AbstractArray) = map(materialize_views, A)
materialize_views(A::AbstractDict) = FlexiGroups.mapvalues(materialize_views, A)
materialize_views(A) = A

"""    collectview(X)

Turn the input into an `AbstractArray`, like `collect` but doesn't copy.
Mostly useful for general handling of arrays and dictionaries. """
collectview(A::AbstractArray) = A
