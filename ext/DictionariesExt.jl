module DictionariesExt
using Dictionaries: AbstractDictionary, Dictionary, ArrayDictionary
import DataManipulation: materialize_views, collectview

materialize_views(A::AbstractDictionary) = map(materialize_views, A)
collectview(A::Union{Dictionary,ArrayDictionary}) = A.values

end
