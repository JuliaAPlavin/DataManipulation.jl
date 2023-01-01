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
    afirst, state = iterate(a)
    arest = Iterators.rest(a, state)
    out = _similar_with_content(f(afirst), T)
    for x ∈ arest
        append!(out, f(x))
    end
    return out
end

_similar_with_content(A::AbstractVector, ::Type{T}) where {T} = similar(A, T) .= A
_similar_with_content(A::AbstractArray, ::Type{T}) where {T} = _similar_with_content(vec(A), T)
_similar_with_content(A, ::Type{T}) where {T} = append!(T[], A)


flatten(x) = flatmap(identity, x)
flatten!(out, x) = flatmap!(identity, out, x)
