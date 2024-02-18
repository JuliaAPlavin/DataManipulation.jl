function vcat_concrete(a::StructVector, b::StructVector)
    constr = result_constructor(eltype(a), eltype(b))
    comps = if eltype(a) <: NamedTuple && eltype(b) <: NamedTuple
        ks = intersect(propertynames(a), propertynames(b))
        map(vcat_concrete, StructArrays.components(a)[ks], StructArrays.components(b)[ks])
    else
        map(vcat_concrete, StructArrays.components(a), StructArrays.components(b))
    end
    ET = Base.promote_op(constr, map(eltype, comps)...)
    StructArray{ET}(comps)
end

function vcat_concrete(a::AbstractVector, b::AbstractVector)
    if fieldcount(eltype(a)) == 0 || fieldcount(eltype(a)) == 0
        vcat(a, b)
    else
        vcat_concrete(StructArray(a), StructArray(b))
    end
end

result_constructor(A, B) = constructorof(A) == constructorof(B) ? constructorof(A) : error("Incompatible eltypes for vcat: $A and $B")
result_constructor(A::Type{<:Tuple}, B::Type{<:AbstractVector}) = constructorof(A)
result_constructor(A::Type{<:AbstractVector}, B::Type{<:Tuple}) = constructorof(A)
result_constructor(A::Type{<:NamedTuple{KA}}, B::Type{<:NamedTuple{KB}}) where {KA,KB} = constructorof(NamedTuple{Tuple(intersect(KA, KB))})
