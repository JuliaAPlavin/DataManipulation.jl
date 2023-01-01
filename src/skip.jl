const skipnan = Base.Fix1(skip, isnan)
Base.skip(pred, X) = Skip(pred, X)

struct Skip{P, TX}
    pred::P
    parent::TX
end

Base.parent(s::Skip) = s.parent
Base.IteratorSize(::Type{<:Skip}) = Base.SizeUnknown()
Base.IteratorEltype(::Type{<:Skip{P, TX}}) where {P, TX} = Base.IteratorEltype(TX)
Base.eltype(::Type{Skip{P, TX}}) where {P, TX} = _try_reducing_type(eltype(TX), P)

Base.IndexStyle(::Type{<:Skip{P, TX}}) where {P, TX} = Base.IndexStyle(TX)
Base.eachindex(s::Skip) = Iterators.filter(i -> !s.pred(@inbounds parent(s)[i]), eachindex(parent(s)))
Base.keys(s::Skip) = Iterators.filter(i -> !s.pred(@inbounds parent(s)[i]), keys(parent(s)))
Base.@propagate_inbounds function Base.getindex(s::Skip, I...)
    v = parent(s)[I...]
    s.pred(v) && throw(MissingException("the value at index $I is skipped"))
    return v
end

function Base.iterate(s::Skip, state...)
    it = iterate(parent(s), state...)
    isnothing(it) && return nothing
    item, state = it
    while s.pred(item)
        it = iterate(parent(s), state)
        isnothing(it) && return nothing
        item, state = it
    end
    item, state
end

Base.collect(s::Skip) = filter(Returns(true), s)

function Base.filter(f, s::Skip)
    y = similar(parent(s), eltype(s), 0)
    for xi in parent(s)
        if !s.pred(xi) && f(xi)
            push!(y, xi)
        end
    end
    y
end

function Base.show(io::IO, s::Skip)
    print(io, "skip(")
    show(io, s.pred)
    print(io, ", ")
    show(io, parent(s))
    print(io, ')')
end


subtract_pred_type(::Type{T}, ::Type) where {T} = T
subtract_pred_type(::Type{T}, ::Type{typeof(ismissing)}) where {T} = Base.nonmissingtype(T)
subtract_pred_type(::Type{T}, ::Type{typeof(isnothing)}) where {T} = Base.nonnothingtype(T)

@inline _helper_f(pred, x) = Val(pred(x))
@inline _can_be(T, P) = Core.Compiler.return_type(_helper_f, Tuple{P, T}) != Val{true}
@inline _try_reducing_type_union(::Type{T}, ::Type{P}) where {T, P} = _can_be(T, P) ? T : Union{}
@inline _try_reducing_type_union(T::Union, ::Type{P}) where {P} = Union{_try_reducing_type_union(T.a, P), _try_reducing_type_union(T.b, P)}


function _try_reducing_type(::Type{T}, ::Type{P}) where {T, P}
    Tu = _try_reducing_type_union(T, P)
    Tsub = subtract_pred_type(T, P)    
    Treduced = Tu <: Tsub ? Tu : Tsub
    return Treduced <: T ? Treduced : T
end
