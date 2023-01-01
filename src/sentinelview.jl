struct SentinelView{T, N, A, I, TS} <: AbstractArray{T, N}
    parent::A
    indices::I
    sentinel::TS
end

function SentinelView(A, I, sentinel)
    @assert !(sentinel isa keytype(A))
    SentinelView{
        if eltype(I) <: keytype(A)
            valtype(A)
        elseif eltype(I) <: Union{keytype(A), typeof(sentinel)}
            Union{valtype(A), typeof(sentinel)}
        else
            error("incompatible: eltype(A) = $(eltype(A)), eltype(I) = $(eltype(I)), sentinel = $sentinel")
        end,
        ndims(I),
        typeof(A),
        typeof(I),
        typeof(sentinel)
    }(A, I, sentinel)
end

Base.IndexStyle(::Type{SentinelView{T, N, A, I}}) where {T, N, A, I} = IndexStyle(I)
Base.size(a::SentinelView) = size(a.indices)

Base.@propagate_inbounds function Base.getindex(a::SentinelView, is::Int...)
    I = a.indices[is...]
    I === a.sentinel ? a.sentinel : a.parent[I]
end

Base.parent(a::SentinelView) = a.parent
Base.parentindices(a::SentinelView) = (a.indices,)

function sentinelview(A, I, sentinel)
    sentinel isa keytype(A) && error("incompatible: keytype(A) = $(keytype(A)), sentinel = $sentinel")
    if A isa AbstractArray && eltype(I) <: keytype(A)
        view(A, I)
    else
        SentinelView(A, I, sentinel)
    end
end
