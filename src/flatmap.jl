function flatmap!(f::Function, out, A)
    empty!(out)
    for a in A
        append!(out, f(a))
    end
    out
end

function flatmap!(f_out::Function, f_in::Function, out, A)
    empty!(out)
    for a in A
        for b in f_out(a)
            push!(out, f_in(a, b))
        end
    end
    out
end


flatmap(f_out::Function, f_in::Function, A) = reduce(vcat, map(a -> map(b -> f_in(a, b), f_out(a)), A))

function flatmap(f::Function, a)
    T = eltype(Base.promote_op(f, eltype(a)))
    it = iterate(a)
    if isnothing(it)
        return _empty_from_type(eltype(a), T)
    end
    afirst, state = it
    arest = Iterators.rest(a, state)
    out = _similar_with_content(f(afirst), T)
    for x ∈ arest
        _out = append!(out, f(x))
        @assert _out === out  # e.g. AxisKeys may return something else from append!
    end
    return out
end

_similar_with_content(A::AbstractVector, ::Type{T}) where {T} = similar(A, T) .= A
_similar_with_content(A::AbstractArray, ::Type{T}) where {T} = _similar_with_content(vec(A), T)
_similar_with_content(A, ::Type{T}) where {T} = append!(T[], A)

_empty_from_type(::Type{Any}, ::Type{T}) where {T} = T[]
_empty_from_type(::Type{AT}, ::Type{T}) where {AT, T} = similar(AT, 0)


flatten(x) = flatmap(identity, x)
flatten!(out, x) = flatmap!(identity, out, x)
