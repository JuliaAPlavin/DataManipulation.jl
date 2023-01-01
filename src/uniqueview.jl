sortview(A; kwargs...) = view(A, sortperm(A; kwargs...))

uniqueview(A) = UniqueView(A, groupfind(identity, A) |> values |> collect)

struct UniqueView{T, TX <: AbstractArray{T}, TI} <: AbstractVector{T}
    parent::TX
    groupedindices::TI
end
UniqueView{T}(parent, groupedindices) where {T} = UniqueView{T, typeof(parent), typeof(groupedindices)}(parent, groupedindices)
UniqueView(parent, groupedindices) = UniqueView{eltype(parent), typeof(parent), typeof(groupedindices)}(parent, groupedindices)

Base.size(A::UniqueView) = size(A.groupedindices)
# Base.keys(A::UniqueView) = keys(parent(A))
# Base.values(A::UniqueView) = mapview(_f(A), values(parent(A)))
# Base.keytype(A::UniqueView) = keytype(parent(A))
# Base.valtype(A::UniqueView) = eltype(A)

Base.parent(A::UniqueView) = getfield(A, :parent)
Base.parentindices(A::UniqueView) = (mapview(first, getfield(A, :groupedindices)),)
function inverseindices(A::UniqueView)
    out = similar(keys(parent(A)))
    for (j, grixs) in pairs(A.groupedindices)
        for i in grixs
            @inbounds out[i] = j
        end
    end
    return out
end

Base.@propagate_inbounds Base.getindex(A::UniqueView, I::Int) = parent(A)[first(A.groupedindices[I])]
Base.@propagate_inbounds Base.setindex!(A::UniqueView, v, I::Int) = (parent(A)[A.groupedindices[I]] .= v; A)