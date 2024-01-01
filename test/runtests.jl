using TestItems
using TestItemRunner
@run_package_tests


@testitem "simple funcs" begin
    @test @inferred(findonly(iseven, [11, 12])) == 2
    @test_throws "multiple elements" findonly(isodd, [1, 2, 3])
    @test_throws "no element" findonly(isodd, [2, 4])

    @test @inferred(filteronly(iseven, [11, 12])) == 12
    @test set([11, 12], @optic(filteronly(iseven, _)), 2) == [11, 2]
    @test_throws "multiple elements" filteronly(isodd, [1, 2, 3])
    @test_throws "is empty" filteronly(isodd, [2, 4])

    @test @inferred(filterfirst(iseven, [11, 12, 14])) == 12
    @test_throws "must be non-empty" filterfirst(isodd, [2, 4])

    @test uniqueonly([1, 1]) == 1
    @test set([1, 1], uniqueonly, 2) == [2, 2]
    @test_throws "multiple unique" uniqueonly([1, 1, 2])
    @test uniqueonly(isodd, [1, 3]) == 1
    @test_throws "multiple unique" uniqueonly(isodd, [1, 1, 2])
end

@testitem "symbols" begin
    x = (a=123, def="c")
    @test :a(x) == 123
    @test S"def"(x) == "c"
end

@testitem "mapset" begin
    using DataManipulation: mapset, mapinsert, mapsetview, mapinsertview
    using StructArrays
    using Accessors

    xs = [(a=1, b=2), (a=3, b=4)]
    @test @inferred(mapset(a=x -> x.b^2, xs)) == [(a=4, b=2), (a=16, b=4)]
    @test @inferred(mapset(a=x -> x.b^2, b=x -> x.a, xs)) == [(a=4, b=1), (a=16, b=3)]
    @test @inferred(mapinsert(c=x -> x.b^2, xs)) == [(a=1, b=2, c=4), (a=3, b=4, c=16)]
    @test @inferred(mapinsert(c=x -> x.b^2, d=x -> x.a + x.b, xs)) == [(a=1, b=2, c=4, d=3), (a=3, b=4, c=16, d=7)]

    @test mapinsert⁻(c=@optic(_.b^2), xs) == [(a=1, c=4), (a=3, c=16)]
    @test mapinsert⁻(c=@optic(_.b^2), d=@optic(_.b), xs) == [(a=1, c=4, d=2), (a=3, c=16, d=4)]

    @test @inferred(mapsetview(a=x -> x.b^2, xs)) == [(a=4, b=2), (a=16, b=4)]
    @test @inferred(mapsetview(a=x -> x.b^2, b=x -> x.a, xs)) == [(a=4, b=1), (a=16, b=3)]
    @test @inferred(mapinsertview(c=x -> x.b^2, xs)) == [(a=1, b=2, c=4), (a=3, b=4, c=16)]
    @test @inferred(mapinsertview(c=x -> x.b^2, d=x -> x.a + x.b, xs)) == [(a=1, b=2, c=4, d=3), (a=3, b=4, c=16, d=7)]

    sa = StructArray(xs)
    sm = @inferred(mapset(a=x -> x.b^2, sa))
    @test sm.a == [4, 16]
    @test sm.b === sa.b
    sm = @inferred(mapinsert(c=x -> x.b^2, sa))
    @test sm.b === sa.b
    @test sm.c == [4, 16]
    sm = @inferred mapinsert⁻(c=@optic(_.b^2), sa)
    @test sm.a === sa.a
    @test sm.c == [4, 16]
end

@testitem "discreterange" begin
    using DataManipulation: discreterange
    using AccessorsExtra
    using Dates
    using Unitful

    @test discreterange(log, 10, 10^5, length=5)::Vector{Int} == [10, 100, 1000, 10000, 100000]
    @test discreterange(log, 2, 10, length=5)::Vector{Int} == [2, 3, 4, 7, 10]
    @test discreterange(@optic(log(ustrip(u"m", _))), 2u"m", 10u"m", length=5) == [2, 3, 4, 7, 10]u"m"
    @test discreterange(@optic(log(ustrip(u"m", _))), 200u"cm", 10u"m", length=5) == [2, 3, 4, 7, 10]u"m"
    @test_broken discreterange(@optic(log(_ / Second(1))), Second(2), Second(10), length=5)

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
    a = [1:5; 5:-1:1]
    as = @inferred sortview(a)
    @test as == [1, 1, 2, 2, 3, 3, 4, 4, 5, 5]
    as[4] = 0
    @test a == [1, 2, 3, 4, 5, 5, 4, 3, 0, 1]
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

    a = [1:5; 5:-1:1]
    au = unique(isodd, a)
    auv = @inferred(uniqueview(isodd, a))::AbstractVector{Int}
    @test au == auv == [1, 2]
    @test a[parentindices(auv)...] == auv
    auv .= [0, 10]
    @test a == [0, 10, 0, 10, 0, 0, 10, 0, 10, 0]


    for uf in (unique, uniqueview)
        Accessors.test_getset_laws(uf, [5, 1, 5, 2, 3], rand(4), rand(4))
        @test modify(x -> 1:length(x), [:a, :b, :a, :a, :b], uf) == [1, 2, 1, 1, 2]
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

@testitem "nest" begin
    using StructArrays

    @test @inferred(nest( (a_x=1, a_y="2", a_z_z=3, b=:z), cr"(a)_(\w+)" )) ===
        (a=(x=1, y="2", z_z=3), b=:z)
    @test @inferred(nest( (a_x=1, a_y="2", a_z_z=3, b=:z), cr"(a)(?:_(\w+))" )) ===
        (a=(x=1, y="2", z_z=3), b=:z)
    @test @inferred(nest( (b=:z,), cr"(a)_(\w+)" )) ===
        (b=:z,)
    @test @inferred(nest( (x_a=1, y_a="2", z_z_a=3, b=:z), cr"(?<y>\w+)_(?<x>a)" )) ===
        (a=(x=1, y="2", z_z=3), b=:z)
    @test @inferred(nest( (x_a=1, y_a="2", z_z_a=3, b_aa=1, b_a="xxx"), cr"(?<y>\w+)_(?<x>a)|(b)_(\w+)" )) ===
        (a=(x=1, y="2", z_z=3, b="xxx"), b=(aa=1,))
    @test @inferred(nest( (x_a=1, y_a="2", z_z_a=3, b_aa=1, b_a="xxx"), cr"(b)_(\w+)|(?<y>\w+)_(?<x>a)" )) ===
        (a=(x=1, y="2", z_z=3), b=(aa=1, a="xxx"))

    @test @inferred(nest( (a_x=1, a_y="2", a_z_z=3, b=:z), cr"(a)_(\w+)" => (cs"xabc", cs"val_\2") )) ===
        (xabc=(val_x=1, val_y="2", val_z_z=3), b=:z)
    @test @inferred(nest( (a_x=1, a_y="2", a_z_z=3, b=:z), cr"(a)(?:_(\w+))" => (cs"xabc", cs"val_\2") )) ===
        (xabc=(val_x=1, val_y="2", val_z_z=3), b=:z)
    @test @inferred(nest( (a=0, a_x=1, a_y="2", a_z_z=3, b=:z), cr"(a)(?:_(\w+))?" => (cs"xabc", cs"val_\2") )) ===
        (xabc=(val_=0, val_x=1, val_y="2", val_z_z=3), b=:z)
    @test @inferred(nest( (a_x=1, a_y="2", a_z_z=3, b=:z), cr"(a)_(\w+)" => (cs"x\1", cs"val", cs"\2") )) ===
        (xa=(val=(x=1, y="2", z_z=3),), b=:z)
    @test @inferred(nest( (a_x=1, a_y="2", a_z_z=3, b=:z), cr"(a)_(\w+)" => (cs"\2_\1",) )) ===
        (x_a=1, y_a="2", z_z_a=3, b=:z)

    @test @inferred(nest( (a_x=1, a_y="2", a_z_z=3, b_1=:z, b_2=5), cr"(a)_(\w+)", cr"(b)_(\d)" => (cs"\1", cs"i\2") )) ===
        (a=(x=1, y="2", z_z=3), b=(i1=:z, i2=5))
    @test_broken @inferred(nest( (a_a=1, a_b=2, b=3), cr"(a)_(\w)", cr"(\w)" => (cs"xx", cs"\1") )) ===
        (a=(a=1, b=2), xx=(b=3,))


    @test_throws "not unique" @inferred(nest( (a_x=1, a_y="2", a_z_z=3, b=:z), cr"(a).+" )) ===
        (a=(x=1, y="2", z_z=3), b=:z)
    @test_throws "not unique" @inferred(nest( (a_x=1, a_y="2", a_z_z=3, b=:z), cr"(a)_(\w+)" => (cs"xabc",) )) ===
        (xabc=(val_x=1, val_y="2", val_z_z=3), b=:z)

    sa = StructArray(a_x=[1], a_y=["2"], a_z_z=[3], b=[:z])
    san = @inferred nest(sa, cr"(a)_(\w+)")
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

# @testitem "vcat" begin
#     X = [(a=1, b=2), (a=2, b=3)]
#     Y = [(a=2, b=1)]

#     # @test vcat_data(X, Y, fields=:setequal)
#     # @test vcat_data(X, Y, fields=:equal)
#     # @test vcat_data(X, Y, fields=intersect)
#     # @test vcat_data(X, Y, fields=union)
#     @test vcat_data(X, Y) == [(a=1, b=2), (a=2, b=3), (a=2, b=1)]
#     @test vcat_data(X, Y; source=@optic(_.src)) == [(a=1, b=2, src=1), (a=2, b=3, src=1), (a=2, b=1, src=2)]
#     @test reduce(vcat_data, (X, Y); source=@optic(_.src)) == [(a=1, b=2, src=1), (a=2, b=3, src=1), (a=2, b=1, src=2)]
#     @test reduce(vcat_data, (; X, Y); source=@optic(_.src)) == [(a=1, b=2, src=:X), (a=2, b=3, src=:X), (a=2, b=1, src=:Y)]
#     @test reduce(vcat_data, Dict("X" => X, "Y" => Y); source=@optic(_.src)) |> sort == [(a=1, b=2, src="X"), (a=2, b=3, src="X"), (a=2, b=1, src="Y")] |> sort
# end

@testitem "_" begin
    import Aqua
    Aqua.test_all(DataManipulation; ambiguities=false, project_toml_formatting=false, piracy=false)  # piracy - only set(unique)?
    Aqua.test_ambiguities(DataManipulation)

    import CompatHelperLocal as CHL
    CHL.@check()
end
