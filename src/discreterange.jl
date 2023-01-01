discreterange(f, start, stop; length::Int) = discreterange(f, promote(start, stop)...; length)
function discreterange(f, start::T, stop::T; length::Int) where {T}
    start >= stop && throw(ArgumentError("start must be less than stop"))
    𝟙 = oneunit(T)
    length - 1 > abs(start - stop) / 𝟙 && throw(ArgumentError("length must be greater than the distance between start and stop"))
    res = Vector{T}(undef, length)
    res[1] = start
    inc = stop > start ? 𝟙 : -𝟙

    step = (f(stop) - f(start)) / (length - 1)
    prev = start
    for i in 2:length
        next = inverse(f)(f(prev) + step)
        if next >= prev + 𝟙
            res[i] = round(T, next)
            prev = next
        else
            prev = prev + inc
            res[i] = round(T, prev)
            step = (f(stop) - f(prev)) / (length - i)
        end
    end
    return res
end
