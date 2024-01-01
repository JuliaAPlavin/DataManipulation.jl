module IntervalSetsExt
using IntervalSets
import DataManipulation: shift_range
import DataManipulation.InverseFunctions: inverse

function shift_range(x, (from, to)::Pair{<:AbstractInterval, <:AbstractInterval}; clamp::Bool=false)
    y = (x - leftendpoint(from)) / _width(from) * _width(to) + leftendpoint(to)
    clamp ? Base.clamp(y, to) : y
end
inverse(f::Base.Fix2{typeof(shift_range), <:Pair}) = Base.Fix2(shift_range, reverse(f.x))

_width(x::AbstractInterval) = rightendpoint(x) - leftendpoint(x)

end