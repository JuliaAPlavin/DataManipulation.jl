mapview(f, X::AbstractArray{T, N}) where {T, N} = MappedArray{Core.Compiler.return_type(f, Tuple{T}), N}(f, X)
mapview(f, X::Dict{K, V}) where {K, V} = MappedDict{K, Core.Compiler.return_type(f, Tuple{V})}(f, X)
mapview(f, X) = MappedAny(f, X)


struct MappedArray{T, N, F, TX <: AbstractArray{<:Any, N}} <: AbstractArray{T, N}
    f::F
    parent::TX
end
MappedArray{T, N}(f, X) where {T, N} = MappedArray{T, N, typeof(f), typeof(X)}(f, X)
parent_type(::Type{<:MappedArray{T, N, F, TX}}) where {T, N, F, TX} = TX

Base.@propagate_inbounds Base.getindex(A::MappedArray, I...) = _getindex(A, to_indices(A, I))
Base.@propagate_inbounds _getindex(A, I::Tuple{Vararg{Integer}}) = _f(A)(parent(A)[I...])
Base.@propagate_inbounds _getindex(A, I::Tuple) = typeof(A)(_f(A), parent(A)[I...])

Base.@propagate_inbounds Base.setindex!(A::MappedArray, v, I...) = _setindex!(A, v, to_indices(A, I))
Base.@propagate_inbounds _setindex!(A, v, I::Tuple{Vararg{Integer}}) = (parent(A)[I...] = set(parent(A)[I...], _f(A), v); A)
Base.@propagate_inbounds _setindex!(A, v, I::Tuple) = (parent(A)[I...] = set.(parent(A)[I...], Ref(_f(A)), v); A)

Base.append!(A::MappedArray, iter) = (append!(parent(A), map(inverse(_f(A)), iter)); A)


struct MappedDict{K, V, F, TX <: AbstractDict{K}} <: AbstractDict{K, V}
    f::F
    parent::TX
end
MappedDict{K, V}(f, X) where {K, V} = MappedDict{K, V, typeof(f), typeof(X)}(f, X)
parent_type(::Type{<:MappedDict{K, V, F, TX}}) where {K, V, F, TX} = TX

Base.@propagate_inbounds Base.getindex(A::MappedDict, I...) = _f(A)(parent(A)[I...])
Base.@propagate_inbounds function Base.setindex!(A::MappedDict, v, k)
    oldv = get(parent(A), k, Base.secret_table_token)
    newv = oldv === Base.secret_table_token ?
        inverse(_f(A))(v) :
        set(oldv, _f(A), v)
    parent(A)[k] = newv
    A
end

Base.get(A::MappedDict, k, default) = get(Returns(default), A, k)
function Base.get(default::Function, A::MappedDict, k)
    v = get(parent(A), k, Base.secret_table_token)
    v === Base.secret_table_token && return default()
    return _f(A)(v)
end



@inline function Base.iterate(A::MappedDict, state...)
	it = iterate(parent(A), state...)
	isnothing(it) ?
        nothing :
        (first(it).first => _f(A)(first(it).second), last(it))
end


struct MappedAny{F, TX}
    f::F
    parent::TX
end
parent_type(::Type{MappedAny{F, TX}}) where {F, TX} = TX

Base.@propagate_inbounds Base.getindex(A::MappedAny, I...) = _f(A)(parent(A)[I...])
Base.@propagate_inbounds Base.setindex!(A::MappedAny, v, I...) = (parent(A)[I...] = set(parent(A)[I...], _f(A), v); A)

Base.eltype(A::MappedAny) = Core.Compiler.return_type(_f(A), Tuple{eltype(parent(A))})
function Base.eltype(::Type{T}) where {T}
    # by default, Base.eltype returns Any for mapped/flattened iterators
    ET = Core.Compiler.return_type(first, Tuple{T})
    ET === Union{} ? Any : ET
end

@inline function Base.iterate(A::MappedAny, state...)
	it = iterate(parent(A), state...)
	isnothing(it) ?
        nothing :
        (_f(A)(first(it)), last(it))
end


const _MTT = Union{MappedArray, MappedDict, MappedAny}
Base.parent(A::_MTT) = getfield(A, :parent)
_f(A::_MTT) = getfield(A, :f)
Base.size(A::_MTT) = size(parent(A))
Base.length(A::_MTT) = length(parent(A))
Base.IndexStyle(::Type{MT}) where {MT <: _MTT} = IndexStyle(parent_type(MT))
Base.IteratorSize(::Type{MT}) where {MT <: _MTT} = Base.IteratorSize(parent_type(MT))
Base.IteratorEltype(::Type{MT}) where {MT <: _MTT} = Base.IteratorEltype(parent_type(MT))
Base.axes(A::_MTT) = axes(parent(A))
Base.keys(A::_MTT) = keys(parent(A))
Base.values(A::_MTT) = mapview(_f(A), values(parent(A)))
Base.keytype(A::_MTT) = keytype(parent(A))
Base.valtype(A::_MTT) = eltype(A)
Base.reverse(A::_MTT, args...; kwargs...) = mapview(_f(A), reverse(parent(A), args...; kwargs...))

for type in (
        :Dims,
        # mimic OffsetArrays signature
        :(Tuple{Union{Integer, AbstractUnitRange}, Vararg{Union{Integer, AbstractUnitRange}}}),
        # disambiguation with Base
        :(Tuple{Union{Integer, Base.OneTo}, Vararg{Union{Integer, Base.OneTo}}}),
    )
    @eval Base.similar(::Type{MT}, dims::$(type)) where {MT <: _MTT} = similar(parent_type(MT), dims)
    @eval Base.similar(A::_MTT, T::Type, dims::$(type)) = similar(parent(A), T, dims)
end



function Base.:(==)(A::Union{AbstractArray, MappedAny}, B::Union{AbstractArray, MappedAny})
    if axes(A) != axes(B)
        return false
    end
    anymissing = false
    for (a, b) in zip(A, B)
        eq = (a == b)
        if ismissing(eq)
            anymissing = true
        elseif !eq
            return false
        end
    end
    return anymissing ? missing : true
end
