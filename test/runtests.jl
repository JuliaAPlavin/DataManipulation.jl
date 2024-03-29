using TestItems
using TestItemRunner
@run_package_tests


@testitem "findonly" begin
    @test @inferred(findonly(iseven, [11, 12])) == 2
    @test_throws "multiple elements" findonly(isodd, [1, 2, 3])
    @test_throws "no element" findonly(isodd, [2, 4])

    @test @inferred(findonly(iseven, (11, 12))) == 2

    @test @inferred(findonly(iseven, (a=1, b=2))) == :b
    @test @inferred(findonly(iseven, (a=1, b=2, c=3))) == :b
    @test_throws "multiple elements" findonly(iseven, (a=1, b=2, c=4))
end

@testitem "filteronly" begin
    @test @inferred(filteronly(iseven, [11, 12])) == 12
    @test set([11, 12], @o(filteronly(iseven, _)), 2) == [11, 2]
    @test delete([11, 12], @o(filteronly(iseven, _))) == [11]

    @test @inferred(filteronly(iseven, (11, 12))) == 12
    @test set((11, 12), @o(filteronly(iseven, _)), 2) == (11, 2)
    @test delete((11, 12), @o(filteronly(iseven, _))) == (11,)

    @test_throws "multiple elements" filteronly(isodd, [1, 2, 3])
    @test_throws "is empty" filteronly(isodd, [2, 4])
end

@testitem "filterfirst" begin
    @test @inferred(filterfirst(iseven, [11, 12, 14])) == 12
    @test set([11, 12, 14], @o(filterfirst(iseven, _)), 2) == [11, 2, 14]
    @test delete([11, 12, 14], @o(filterfirst(iseven, _))) == [11, 14]
    @test_throws "must be non-empty" filterfirst(isodd, [2, 4])

    @test @inferred(filterfirst(iseven, (11, 12, 14))) == 12
    @test set((11, 12, 14), @o(filterfirst(iseven, _)), 2) == (11, 2, 14)
    @test delete((11, 12, 14), @o(filterfirst(iseven, _))) == (11, 14)
end

@testitem "uniqueonly" begin
    @test uniqueonly([1, 1]) == 1
    @test set([1, 1], uniqueonly, 2) == [2, 2]
    @test_throws "multiple unique" uniqueonly([1, 1, 2])

    @test uniqueonly(isodd, [1, 3]) == 1
    @test_throws "multiple unique" uniqueonly(isodd, [1, 1, 2])

    @test uniqueonly((1, 1)) == 1
    @test set((1, 1), uniqueonly, 2) == (2, 2)
    @test uniqueonly(isodd, (1, 3)) == 1
end

@testitem "symbols" begin
    x = (a=123, def="c")
    @test :a(x) == 123
    @test S"def"(x) == "c"
end

@testitem "discreterange" begin
    using DataManipulation: discreterange
    using AccessorsExtra
    using Dates
    using DateFormats
    using Unitful

    @test discreterange(log, 10, 10^5, length=5)::Vector{Int} == [10, 100, 1000, 10000, 100000]
    @test discreterange(log, 2, 10, length=5)::Vector{Int} == [2, 3, 4, 7, 10]
    @test discreterange(log, 2, 10, length=5, mul=1.)::Vector{Float64} == [2, 3, 4, 7, 10]
    @test discreterange(log, 2, 10, length=5, mul=0.1)::Vector{Float64} == [2, 3, 4.5, 6.7, 10]
    @test discreterange(@o(log(ustrip(u"m", _))), 2u"m", 10u"m", length=5) == [2, 3, 4, 7, 10]u"m"
    @test_throws Exception discreterange(@o(log(ustrip(u"m", _))), 200u"cm", 10u"m", length=5) == [2, 3, 4, 7, 10]u"m"
    @test discreterange(@o(log(ustrip(u"m", _))), 200u"cm", 10u"m", length=5, mul=1u"m") == [2, 3, 4, 7, 10]u"m"
    @test_broken (discreterange(@o(log(_ / Second(1))), Second(2), Second(10), length=5); true)
    @test discreterange(@o(log(_ /ₜ Second(1))), Second(2), Second(10), length=5) == [Second(2), Second(3), Second(4), Second(7), Second(10)]

    @testset for a in [1, 10, 100, 1000, 10^10], b in [1, 10, 100, 1000, 10^10], len in [2:100; 12345]
        a >= b && continue
        if len > abs(a - b) + 1
            @test_throws "length must be greater" discreterange(log, a, b, length=len)
            continue
        end
        rng = discreterange(log, a, b, length=len)::Vector{Int}
        @test length(rng) == len
        @test allunique(rng)
        @test issorted(rng, rev=a > b)
        @test minimum(rng) == min(a, b)
        @test maximum(rng) == max(a, b)
        @test discreterange(log, a, b, length=len, mul=1)::Vector{Int} == rng
        @test discreterange(log, a, b, length=len, mul=1.0)::Vector{Float64} == rng
        @test 10 .* discreterange(log, 0.1*a, 0.1*b, length=len, mul=0.1)::Vector{Float64} ≈ rng
    end
end

@testitem "shift_range" begin
    using IntervalSets
    using InverseFunctions

    f = Base.Fix2(shift_range, 1..2 => 20..30)
    @test f(1) == 20
    @test f(1.6) == 26
    @test f(-2) == -10
    InverseFunctions.test_inverse(f, 1.2)

    f = Base.Fix2(shift_range, 1..2 => 30..20)
    @test f(1) == 30
    @test f(1.6) == 24
    @test f(-2) == 60
    InverseFunctions.test_inverse(f, 1.2)

    @test shift_range(1, 1..2 => 20..30; clamp=true) == 20
    @test shift_range(1.6, 1..2 => 20..30; clamp=true) == 26
    @test shift_range(-2, 1..2 => 20..30; clamp=true) == 20
end

@testitem "rev" begin
    @testset for A in (
        rand(Int, 5),
        string.(rand(Int, 5)),
        [1., NaN, 0.],
        Any[10, 1.0]
    )
        @test isequal(sort(A; rev=true), sort(A; by=rev))
        @test isequal(sort(A; rev=true), sort(A; by=x -> (rev(x^1), x)))
    end
end

@testitem "interactions" begin
    using Dictionaries
    using StructArrays

    a = mapview(x -> x + 1, skip(isnan, [1, 2, NaN, 3]))
    @test eltype(a) == Float64
    @test @inferred(a[1]) == 2
    @test_throws "is skipped" a[3]
    @test @inferred(sum(a)) == 9

    a = skip(isnan, mapview(x -> x + 1, [1, 2, NaN, 3]))
    @test eltype(a) == Float64
    @test @inferred(a[1]) == 2
    @test_throws "is skipped" a[3]
    @test @inferred(sum(a)) == 9

    a = StructArray(a=[missing, -1, 2, 3])
    sa = @inferred skip(x -> ismissing(x.a) || x.a < 0, a)
    @test collect(sa.a) == [2, 3]
end

@testitem "sortview" begin
    using Accessors

    a = [1:5; 5:-1:1]
    as = @inferred sortview(a)
    @test as == [1, 1, 2, 2, 3, 3, 4, 4, 5, 5]
    as[4] = 0
    @test a == [1, 2, 3, 4, 5, 5, 4, 3, 0, 1]
    @test set([5, 1, 4, 2, 3], sortview, 10 .* (1:5)) == [50, 10, 40, 20, 30]
    @test modify(cumsum, [4, 1, 4, 2, 3], sortview) == [10, 1, 14, 3, 6]
end

@testitem "uniqueview" begin
    a = [1:5; 5:-1:1]
    a_orig = copy(a)

    au = unique(a)
    auv = @inferred(uniqueview(a))::AbstractVector{Int}
    @test auv == au == 1:5
    @test a[parentindices(auv)...] == auv
    @test auv[DataManipulation.inverseindices(auv)] == a

    auv[1] = 0
    @test a == [0; 2:5; 5:-1:2; 0]
    a .= a_orig
    
    cnt = Ref(0)
    f(x) = (cnt[] += 1; x * 10)
    auv .= f.(auv)
    @test a == 10 .* a_orig
    @test auv == unique(a)
    @test cnt[] == 5

    a = [1:5; 5:-1:1]
    au = unique(isodd, a)
    auv = @inferred(uniqueview(isodd, a))::AbstractVector{Int}
    @test au == auv == [1, 2]
    @test a[parentindices(auv)...] == auv
    auv .= [0, 10]
    @test a == [0, 10, 0, 10, 0, 0, 10, 0, 10, 0]

    for uf in (unique, uniqueview)
        Accessors.test_getset_laws(uf, [5, 1, 5, 2, 3], rand(4), rand(4))
        @test @inferred(modify(x -> 1:length(x), [:a, :b, :a, :a, :b], uf)) == [1, 2, 1, 1, 2]

        cnt = Ref(0)
        f(x) = (cnt[] += 1; 2x)
        @test modify(f, [1:5; 1:10], @o(uf(_) |> Elements())) == [2:2:10; 2:2:20]
        @test cnt[] == 10
    end
end

@testitem "materialize_views" begin
    using Dictionaries: dictionary, Dictionary, AbstractDictionary
    using SentinelViews

    @test materialize_views([10, 20, 30])::Vector{Int} == [10, 20, 30]
    @test materialize_views(view([10, 20, 30], [1, 2]))::Vector{Int} == [10, 20]
    @test materialize_views(filterview(x -> true, [10, 20, 30]))::Vector{Int} == [10, 20, 30]
    @test materialize_views(mapview(x -> 10x, [1, 2, 3]))::Vector{Int} == [10, 20, 30]
    @test materialize_views(skip(isnan, [10, 20, NaN]))::Vector{Float64} == [10, 20]
    @test materialize_views(sentinelview([10, 20, 30], [1, nothing, 3], nothing))::Vector{Union{Int, Nothing}} == [10, nothing, 30]
    @test materialize_views(group(isodd, 3 .* [1, 2, 3, 4, 5]))::AbstractDictionary{Bool, Vector{Int}} == dictionary([true => [3, 9, 15], false => [6, 12]])
    @test materialize_views(group(isodd, 3 .* [1, 2, 3, 4, 5]; restype=Dict))::Dict{Bool, Vector{Int}} == Dict([true => [3, 9, 15], false => [6, 12]])
end

@testitem "collectview" begin
    @test collectview([10, 20, 30])::Vector{Int} == [10, 20, 30]
    @test collectview(view([10, 20, 30], [1, 2]))::SubArray{Int} == [10, 20]
    @test collectview(group(isodd, 3 .* [1, 2, 3, 4, 5]))::Vector{<:SubArray{Int}} == [[3, 9, 15], [6, 12]]
end

@testitem "comptime indexing" begin
    using StructArrays

    nt = (a_1=1, a_2=10., b_1=100)
    @test nt[sr"a_\d"] === (a_1 = 1, a_2 = 10.)
    @test nt[sr"a_(\d)" => ss"xxx_\1_xxx"] === (xxx_1_xxx = 1, xxx_2_xxx = 10.)
    @test nt[sr"a_(\d)" => ss"x_\1", sr"b.*"] === (x_1 = 1, x_2 = 10., b_1 = 100)
    @test_broken (nt[sr"a_(\d)" => (x -> x), sr"b.*"]; true)  # cannot avoid "method too new" error

    A = StructArray(a_1=[1], a_2=[10.], b_1=[100])
    B = A[sr"a_\d"]
    @test B == StructArray(a_1=[1], a_2=[10.])
    @test B.a_1 === A.a_1

    @test @delete(nt[sr"a_\d"]) === (b_1 = 100,)
    B = @delete A[sr"a_\d"]
    @test B == StructArray(b_1=[100])
    @test B.b_1 === A.b_1

    @test @modify(x -> x + 1, nt[sr"a_\d"] |> Elements()) === (a_1 = 2, a_2 = 11., b_1 = 100)
    @test (@inferred modify(x -> x + 1, nt, @optic _[sr"a_\d"] |> Elements())) === (a_1 = 2, a_2 = 11., b_1 = 100)

    @test (@inferred modify(x -> x .+ ndims(x), A, @optic _[sr"a_\d"] |> Properties())) == StructArray(a_1=[2], a_2=[11.], b_1=[100])
end

@testitem "nest" begin
    using StructArrays

    @test @inferred(nest( (a_x=1, a_y="2", a_z_z=3, b=:z), sr"(a)_(\w+)" )) ===
        (a=(x=1, y="2", z_z=3), b=:z)
    @test @inferred(nest( (a_x=1, a_y="2", a_z_z=3, b=:z), sr"(a)(?:_(\w+))" )) ===
        (a=(x=1, y="2", z_z=3), b=:z)
    @test @inferred(nest( (b=:z,), sr"(a)_(\w+)" )) ===
        (b=:z,)
    @test @inferred(nest( (x_a=1, y_a="2", z_z_a=3, b=:z), sr"(?<y>\w+)_(?<x>a)" )) ===
        (a=(x=1, y="2", z_z=3), b=:z)
    @test @inferred(nest( (x_a=1, y_a="2", z_z_a=3, b_aa=1, b_a="xxx"), sr"(?<y>\w+)_(?<x>a)|(b)_(\w+)" )) ===
        (a=(x=1, y="2", z_z=3, b="xxx"), b=(aa=1,))
    @test @inferred(nest( (x_a=1, y_a="2", z_z_a=3, b_aa=1, b_a="xxx"), sr"(b)_(\w+)|(?<y>\w+)_(?<x>a)" )) ===
        (a=(x=1, y="2", z_z=3), b=(aa=1, a="xxx"))

    @test @inferred(nest( (a_x=1, a_y="2", a_z_z=3, b=:z), sr"(a)_(\w+)" => (ss"xabc", ss"val_\2") )) ===
        (xabc=(val_x=1, val_y="2", val_z_z=3), b=:z)
    @test @inferred(nest( (a_x=1, a_y="2", a_z_z=3, b=:z), sr"(a)(?:_(\w+))" => (ss"xabc", ss"val_\2") )) ===
        (xabc=(val_x=1, val_y="2", val_z_z=3), b=:z)
    @test @inferred(nest( (a=0, a_x=1, a_y="2", a_z_z=3, b=:z), sr"(a)(?:_(\w+))?" => (ss"xabc", ss"val_\2") )) ===
        (xabc=(val_=0, val_x=1, val_y="2", val_z_z=3), b=:z)
    @test @inferred(nest( (a_x=1, a_y="2", a_z_z=3, b=:z), sr"(a)_(\w+)" => (ss"x\1", ss"val", ss"\2") )) ===
        (xa=(val=(x=1, y="2", z_z=3),), b=:z)
    @test @inferred(nest( (a_x=1, a_y="2", a_z_z=3, b=:z), sr"(a)_(\w+)" => (ss"\2_\1",) )) ===
        (x_a=1, y_a="2", z_z_a=3, b=:z)

    @test @inferred(nest( (a_x=1, a_y="2", a_z_z=3, b_1=:z, b_2=5), sr"(a)_(\w+)", sr"(b)_(\d)" => (ss"\1", ss"i\2") )) ===
        (a=(x=1, y="2", z_z=3), b=(i1=:z, i2=5))
    @test_broken @inferred(nest( (a_a=1, a_b=2, b=3), sr"(a)_(\w)", sr"(\w)" => (ss"xx", ss"\1") )) ===
        (a=(a=1, b=2), xx=(b=3,))


    @test_throws "not unique" @inferred(nest( (a_x=1, a_y="2", a_z_z=3, b=:z), sr"(a).+" )) ===
        (a=(x=1, y="2", z_z=3), b=:z)
    @test_throws "not unique" @inferred(nest( (a_x=1, a_y="2", a_z_z=3, b=:z), sr"(a)_(\w+)" => (ss"xabc",) )) ===
        (xabc=(val_x=1, val_y="2", val_z_z=3), b=:z)

    sa = StructArray(a_x=[1], a_y=["2"], a_z_z=[3], b=[:z])
    san = @inferred nest(sa, sr"(a)_(\w+)")
    @test only(san) === (a=(x=1, y="2", z_z=3), b=:z)
    @test san.a.x === sa.a_x
    @test san.b === sa.b
end


# @testitem "(un)nest" begin
#     @test @inferred(unnest((a=(x=1, y="2"), b=:z))) === (a_x=1, a_y="2", b=:z)
#     @test_throws ErrorException unnest((a=(x=1, y="2"), a_x=3, b=:z))
#     @test @inferred(unnest((a=(x=1, y=(u="2", w=3)), b=:z))) === (a_x=1, a_y=(u="2", w=3), b=:z)

#     f = nt -> unnest(nt, ())
#     @test @inferred(f((a=(x=1, y="2"), b=:z))) === (a=(x=1, y="2"), b=:z)
#     f = nt -> unnest(nt, (:a,))
#     @test @inferred(f((a=(x=1, y="2"), b=:z))) === (a_x=1, a_y="2", b=:z)
#     f = nt -> unnest(nt, :a)
#     @test @inferred(f((a=(x=1, y="2"), b=:z))) === (a_x=1, a_y="2", b=:z)
#     @test_throws ErrorException unnest((a=(x=1, y="2"), b=:z), (:a, :b))

#     f = nt -> unnest(nt, :a => nothing)
#     @test @inferred(f((a=(x=1, y="2"), b=:z))) === (x=1, y="2", b=:z)

#     # @test nest( (a_x=1, a_y="2", a_z_z=3, b=:z), startswith(:a_) ) == (a=(x=1, y="2", z_z=3), b=:z)
#     # @test nest( (x_a=1, y_a="2", z_z_a=3, b=:z), endswith(:_a) ) == (a=(x=1, y="2", z_z=3), b=:z)
#     # @test nest( (x_a=1, y_a="2", z_z_a=3, b_aa=1), endswith(:_a), startswith(:b) ) == (a=(x=1, y="2", z_z=3), b=(aa=1,))

#     # @test f( (a_x=1, a_y="2", a_z_z=3, b=:z), x -> (a=(x=x.a_x, y=x.a_y, z_z=x.a_z_z),) )
#     # @test @replace( (name="abc", ra=1, dec=2), (coords=(_.ra, _.dec),) ) == (name="abc", coords=(1, 2))
#     # @test @replace( (name="abc", ra=1, dec=2), (coords=(@o(_.ra), @o(_.dec)),) ) == (name="abc", coords=(1, 2))
#     # @test replace( (name="abc", ra=1, dec=2), @o(_[(:ra, :dec)]) => tuple => @o(_.coords) ) == (name="abc", coords=(1, 2))
# end

@testitem "vcat" begin
    using StructArrays

    X = StructArray(x=[(a=1, b=2), (a=2, b=3)])
    Y = StructArray(x=[(a=3,), (a=4,)])
    @test vcat(X, Y).x::Vector{NamedTuple} == [(a=1, b=2), (a=2, b=3), (a=3,), (a=4,)]
    @test vcat_concrete(X, Y).x::AbstractVector{@NamedTuple{a::Int}} == [(a=1,), (a=2,), (a=3,), (a=4,)]
    @test vcat_concrete(X, Y).x.a == [1, 2, 3, 4]

    # X = [(a=1, b=2), (a=2, b=3)]
    # Y = [(a=2, b=1)]

    # @test vcat_data(X, Y, fields=:setequal)
    # @test vcat_data(X, Y, fields=:equal)
    # @test vcat_data(X, Y, fields=intersect)
    # @test vcat_data(X, Y, fields=union)
    # @test vcat_data(X, Y) == [(a=1, b=2), (a=2, b=3), (a=2, b=1)]
    # @test vcat_data(X, Y; source=@o(_.src)) == [(a=1, b=2, src=1), (a=2, b=3, src=1), (a=2, b=1, src=2)]
    # @test reduce(vcat_data, (X, Y); source=@o(_.src)) == [(a=1, b=2, src=1), (a=2, b=3, src=1), (a=2, b=1, src=2)]
    # @test reduce(vcat_data, (; X, Y); source=@o(_.src)) == [(a=1, b=2, src=:X), (a=2, b=3, src=:X), (a=2, b=1, src=:Y)]
    # @test reduce(vcat_data, Dict("X" => X, "Y" => Y); source=@o(_.src)) |> sort == [(a=1, b=2, src="X"), (a=2, b=3, src="X"), (a=2, b=1, src="Y")] |> sort
end

@testitem "_" begin
    import Aqua
    Aqua.test_all(DataManipulation; ambiguities=false, piracies=false)  # piracy - only set(unique)?
    Aqua.test_ambiguities(DataManipulation)

    import CompatHelperLocal as CHL
    CHL.@check()
end
