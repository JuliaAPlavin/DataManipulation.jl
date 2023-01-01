mutate(f, A) = map(a -> merge(a, f(a)), A)
mutate(A; kwargs...) = mutate(a -> map(fx -> fx(a), values(kwargs)), A)

function mutate(A::StructArray{<:NamedTuple}; kwargs...)
    new_comps = map(values(kwargs)) do fx
        map(fx, A)
    end
    return StructArray(merge(StructArrays.components(A), new_comps))
end