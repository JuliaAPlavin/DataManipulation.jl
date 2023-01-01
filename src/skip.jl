const skipnan = Base.Fix1(skip, isnan)
Base.skip(pred, X) = Skip(pred, X)

struct Skip{P, TX}
    pred::P
    parent::TX
end

_pred(s::Skip) = getfield(s, :pred)
Base.parent(s::Skip) = getfield(s, :parent)
Base.IteratorSize(::Type{<:Skip}) = Base.SizeUnknown()
Base.IteratorEltype(::Type{<:Skip{P, TX}}) where {P, TX} = Base.IteratorEltype(TX)
Base.eltype(::Type{Skip{P, TX}}) where {P, TX} = _try_reducing_type(_eltype(TX), P)

Base.IndexStyle(::Type{<:Skip{P, TX}}) where {P, TX} = Base.IndexStyle(TX)
Base.eachindex(s::Skip) = Iterators.filter(i -> !_pred(s)(@inbounds parent(s)[i]), eachindex(parent(s)))
Base.keys(s::Skip) = Iterators.filter(i -> !_pred(s)(@inbounds parent(s)[i]), keys(parent(s)))

Base.@propagate_inbounds function Base.getindex(s::Skip, I...)
    v = parent(s)[I...]
    _pred(s)(v) && throw(MissingException("the value at index $I is skipped"))
    return v
end

Base.@propagate_inbounds function Base.setindex!(s::Skip, v, I...)
    oldv = parent(s)[I...]
    _pred(s)(oldv) && throw(MissingException("existing value at index $I is skipped"))
    _pred(s)(v) && throw(MissingException("new value to be set at index $I is skipped"))
    return setindex!(parent(s), v, I...)
end

function Base.iterate(s::Skip, state...)
    it = iterate(parent(s), state...)
    isnothing(it) && return nothing
    item, state = it
    while _pred(s)(item)
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
        if !_pred(s)(xi) && f(xi)
            push!(y, xi)
        end
    end
    y
end

Base.BroadcastStyle(::Type{<:Skip}) = Broadcast.Style{Skip}()
Base.BroadcastStyle(::Broadcast.Style{Skip}, ::Broadcast.DefaultArrayStyle) = Broadcast.Style{Skip}()
Base.BroadcastStyle(::Broadcast.DefaultArrayStyle, ::Broadcast.Style{Skip}) = Broadcast.Style{Skip}()
Broadcast.materialize!(::Broadcast.Style{Skip}, dest::Skip, bc::Broadcast.Broadcasted) = copyto!(dest, bc)
function Base.copyto!(dest::Skip, src::Broadcast.Broadcasted)
    destiter = eachindex(dest)
    y = iterate(destiter)
    for x in src
        isnothing(y) && throw(ArgumentError("destination has fewer elements than required"))
        @inbounds dest[y[1]] = x
        y = iterate(destiter, y[2])
    end
    return dest
end

Base.getproperty(A::Skip, p::Symbol) = mapview(Accessors.PropertyLens(p), A)
Base.getproperty(A::Skip, p) = mapview(Accessors.PropertyLens(p), A)

function Base.show(io::IO, s::Skip)
    print(io, "skip(")
    show(io, _pred(s))
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
