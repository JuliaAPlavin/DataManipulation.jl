"""    sortview(X; kws...)

Like `sort(X; kws...)`, but returns a view instead of a copy. """
sortview(A; kwargs...) = view(A, sortperm(A; kwargs...))

"""    uniqueview([f], X)
Like `unique([f], X)`, but returns a view instead of a copy. """
uniqueview(A) = uniqueview(identity, A)
uniqueview(f::Function, A) = UniqueView(A, groupfind(f, A) |> values |> collect)

struct UniqueView{T, TX <: AbstractArray{T}, TI} <: AbstractVector{T}
    parent::TX
    groupedindices::TI
end

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


Accessors.set(obj, ::typeof(sortview), val) = @set obj[sortperm(obj)] = val
function Accessors.modify(f, obj, o::typeof(sortview))
    sv = o(obj)
    @set obj[parentindices(sv)...] = f(sv)
end

function Accessors.set(obj, ::typeof(uniqueview), val)
    IXs = inverseindices(uniqueview(obj))
    setall(obj, Elements(), @views val[IXs])
end

function Accessors.modify(f, obj, ::typeof(uniqueview))
    uv = uniqueview(obj)
    val = f(uv)
    setall(obj, Elements(), @views val[inverseindices(uv)])
end

function Accessors.set(obj, ::typeof(unique), val)
    IXs = inverseindices(uniqueview(obj))
    setall(obj, Elements(), @views val[IXs])
end
