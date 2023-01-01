"""    filterview(f, X)

Like `filter(f, X)`, but returns a view instead of a copy. """
function filterview end

filterview(f, X::AbstractArray) = @view X[findall(f, X)]
filterview(f, X::AbstractDict) = FilteredDict(f, X)
filterview(f, X::AbstractDictionary) = Dictionaries.filterview(f, X)


struct FilteredDict{K, V, D <: AbstractDict{K, V}, P} <: AbstractDict{K, V}
    pred::P
    parent::D
end

Base.parent(f::FilteredDict) = f.parent
Base.IteratorSize(::Type{<:FilteredDict}) = Base.SizeUnknown()
Base.length(f::FilteredDict) = count(f.pred, f.parent)

Base.get(f::FilteredDict, k, default) = get(Returns(default), f, k)

function Base.get(default::Function, f::FilteredDict, k)
    v = get(parent(f), k, Base.secret_table_token)
    v === Base.secret_table_token && return default()
    f.pred(k => v) || return default()
    return v
end

function Base.iterate(f::FilteredDict, state0...)
    (kv, state) = iterate(parent(f), state0...)
    while !f.pred(kv)
        it = iterate(parent(f), state)
        isnothing(it) && return nothing
        (kv, state) = it
    end
    return kv, state
end
