materialize_views(A::AbstractArray) = map(materialize_views, A)
materialize_views(A::Dictionary) = map(materialize_views, A)
materialize_views(A::Dict) = FlexiGroups.mapvalues(materialize_views, A)
materialize_views(A::StructArray) = StructArray(map(materialize_views, StructArrays.components(A)))
materialize_views(A) = A
