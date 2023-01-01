using ArraysExtra
using StructArrays
using AxisKeys
using Dictionaries: dictionary, AbstractDictionary
using TypedTables: Table
using Test


@testset "symbols" begin
    x = (a=123, def="c")
    @test :a(x) == 123
    @test S"def"(x) == "c"
end

@testset "filtermap" begin
    X = 1:10
    Y = filtermap(x -> x % 3 == 0 ? Some(x^2) : nothing, X)
    @test Y == [9, 36, 81]
    @test typeof(Y) == Vector{Int}

    @test filtermap(x -> x % 3 == 0 ? x^2 : nothing, X) == [9, 36, 81]
    @test filtermap(x -> x % 3 == 0 ? Some(nothing) : nothing, X) == [nothing, nothing, nothing]

    @test filtermap(x -> x % 3 == 0 ? Some(x^2) : nothing, (1, 2, 3, 4, 5, 6)) === (9, 36)

    @test filtermap(x -> isodd(x) ? Some(x^2) : nothing, KeyedArray([1, 2, 3], x=[10, 20, 30]))::KeyedArray == KeyedArray([1, 9], x=[10, 30])
end

@testset "flatmap" begin
    @testset "outer func" begin
        @test @inferred(flatmap(i->1:i, 1:3))::Vector{Int} == [1, 1,2, 1,2,3]

        a = @inferred(flatmap(i -> StructVector(a=1:i), [2, 3]))::StructArray
        @test a == [(a=1,), (a=2,), (a=1,), (a=2,), (a=3,)]
        @test a.a == [1, 2, 1, 2, 3]

        cnt = Ref(0)
        @test flatmap(i -> [cnt[] += 1], 1:3)::Vector{Int} == [1, 2, 3]
        @test cnt[] == 3

        @test @inferred(flatmap(i -> (j for j in 1:i), (i for i in 1:3))) == [1, 1,2, 1,2,3]  # XXX: Vector{Any}
        @test @inferred(flatmap(i -> 1:i, [1 3; 2 4]))::Vector{Int} == [1, 1,2, 1,2,3, 1,2,3,4]
        @test @inferred(flatmap(i -> reshape(1:i, 2, :), [2, 4]))::Vector{Int} == [1, 2, 1, 2, 3, 4]

        @test_broken flatmap(i -> 1:i, [1][1:0]) == []
        @test @inferred(flatmap(i -> collect(1:i), [1][1:0]))::Vector{Int} == []
        @test @inferred(flatmap(i -> (j for j in 1:i), (i for i in 1:0))) == []  # XXX: Vector{Any}

        X = [(a=[1, 2],), (a=[3, 4],)]
        out = Int[]
        @test flatmap!(x -> x.a, out, X) === out == [1, 2, 3, 4]
    end

    @testset "outer & inner func" begin
        X = [(a=[1, 2],), (a=[3, 4],)]
        @test flatmap(x -> x.a, (x, a) -> (a, sum(x.a)), X) == [(1, 3), (2, 3), (3, 7), (4, 7)]

        @test flatmap(x -> x.a, (x, a) -> (a, sum(x.a)), X[1:0])::Vector{Int} == []

        out = Tuple{Int, Int}[]
        @test flatmap!(x -> x.a, (x, a) -> (a, sum(x.a)), out, X) === out == [(1, 3), (2, 3), (3, 7), (4, 7)]

        @test @inferred(flatmap(i -> (j for j in 1:i), (i, j) -> i + j, (i for i in 1:3))) == [2, 3,4, 4,5,6]

        cnt_out = Ref(0)
        cnt_in = Ref(0)
        @test flatmap(i -> [cnt_out[] += 1], (i, j) -> (cnt_in[] += 1), 1:3) == [1, 2, 3]
        @test cnt_out[] == 3
        @test cnt_in[] == 3

        Y = flatmap(x -> StructArray(;x.a), (x, a) -> (a, sum(x.a)), X)
        @test Y == [((a=1,), 3), ((a=2,), 3), ((a=3,), 7), ((a=4,), 7)]
        @test Y isa StructArray
    end

    @testset "flatten" begin
        @test @inferred(flatten([1:1, 1:2, 1:3])) == [1, 1,2, 1,2,3]
        out = Int[]
        @test flatten!(out, [1:1, 1:2, 1:3]) === out == [1, 1,2, 1,2,3]

        a = @inferred(flatten([StructVector(a=[1, 2]), StructVector(a=[1, 2, 3])]))::StructArray
        @test a == [(a=1,), (a=2,), (a=1,), (a=2,), (a=3,)]
        @test a.a == [1, 2, 1, 2, 3]

        @test_throws "_out === out" flatten([KeyedArray([1, 2], x=10:10:20), KeyedArray([1, 2, 3], x=10:10:30)])
        a = @inferred(flatten([KeyedArray([1, 2], x=[10, 20]), KeyedArray([1, 2, 3], x=[10, 20, 30])]))::KeyedArray
        @test a == KeyedArray([1, 2, 1, 2, 3], x=[10, 20, 10, 20, 30])

        @test @inferred(flatten([[]])) == []
        @test @inferred(flatten(Vector{Int}[])) == []
        @test @inferred(flatten([StructVector(a=[1, 2])][1:0])) == []
        @test flatten(Any[[]]) == []
        @test flatten([]) == []
    end
end

@testset "mutate" begin
    X = [(a=1, b=(c=2,)), (a=3, b=(c=4,))]
    @test mutate(x -> (c=x.a^2,), X) == [(a=1, b=(c=2,), c=1), (a=3, b=(c=4,), c=9)]
    @test mutate(x -> (a=x.a^2,), X) == [(a=1, b=(c=2,)), (a=9, b=(c=4,))]
    @test mutate(c=x -> x.a^2, X) == [(a=1, b=(c=2,), c=1), (a=3, b=(c=4,), c=9)]
    @test mutate(c=x -> x.a^2, d=x -> x.a + 1, X) == [(a=1, b=(c=2,), c=1, d=2), (a=3, b=(c=4,), c=9, d=4)]
    @test mutate(x -> (b=(d=x.a,),), X) == [(a=1, b=(d=1,)), (a=3, b=(d=3,))]

    S = StructArray(X)
    Sm = mutate(c=x -> x.a^2, S)
    @test eltype(Sm) == @NamedTuple{a::Int, b::@NamedTuple{c::Int}, c::Int}
    @test Sm.a === S.a
    @test Sm.b === S.b
    @test Sm.c == [1, 9]
end

@testset "group" begin
    @testset "basic" begin
        xs = 3 .* [1, 2, 3, 4, 5]
        g = @inferred group(isodd, xs)
        @test g == Dict(false => [6, 12], true => [3, 9, 15])
        @test isconcretetype(eltype(g))
        @test eltype(g) <: Pair{Bool, <:SubArray{Int}}

        # ensure we get a copy
        xs[1] = 123
        @test g == Dict(false => [6, 12], true => [3, 9, 15])


        xs = 3 .* [1, 2, 3, 4, 5]
        g = @inferred groupview(isodd, xs)
        @test g == Dict(false => [6, 12], true => [3, 9, 15])
        @test isconcretetype(eltype(g))
        @test eltype(g) <: Pair{Bool, <:SubArray{Int}}

        # ensure we get a view
        xs[1] = 123
        @test g == Dict(false => [6, 12], true => [123, 9, 15])


        xs = 3 .* [1, 2, 3, 4, 5]
        g = @inferred groupfind(isodd, xs)
        @test g == Dict(false => [2, 4], true => [1, 3, 5])
        @test isconcretetype(eltype(g))
        @test eltype(g) <: Pair{Bool, <:SubArray{Int}}


        g = @inferred(group(isnothing, [1, 2, 3, nothing, 4, 5, nothing]))
        @test g == Dict(false => [1, 2, 3, 4, 5], true => [nothing, nothing])
        @test eltype(g) <: Pair{Bool, <:SubArray{Union{Nothing, Int}}}
    end

    @testset "groupmap" begin
        xs = 3 .* [1, 2, 3, 4, 5]
        @test @inferred(groupmap(isodd, length, xs)) == Dict(false => 2, true => 3)
        @test @inferred(groupmap(isodd, first, xs)) == Dict(false => 6, true => 3)
        @test @inferred(groupmap(isodd, last, xs)) == Dict(false => 12, true => 15)
        @test_throws "exactly one element" groupmap(isodd, only, xs)
        @test @inferred(groupmap(isodd, only, [10, 11])) == Dict(false => 10, true => 11)
    end

    @testset "structarray" begin
        xs = StructArray(a=3 .* [1, 2, 3, 4, 5])
        g = @inferred group(x -> isodd(x.a), xs)
        @test g == Dict(false => [(a=6,), (a=12,)], true => [(a=3,), (a=9,), (a=15,)])
        @test isconcretetype(eltype(g))
        @test g[false].a == [6, 12]

        g = @inferred groupview(x -> isodd(x.a), xs)
        @test g == Dict(false => [(a=6,), (a=12,)], true => [(a=3,), (a=9,), (a=15,)])
        @test isconcretetype(eltype(g))
        @test g[false].a == [6, 12]
    end

    @testset "keyedarray" begin
        xs = KeyedArray(1:5, a=3 .* [1, 2, 3, 4, 5])
        g = @inferred group(isodd, xs)
        @test g == Dict(false => [2, 4], true => [1, 3, 5])
        @test isconcretetype(eltype(g))
        @test_broken axiskeys(g[false]) == ([6, 12],)
        @test_broken g[false](a=6) == 2

        g = @inferred groupview(isodd, xs)
        @test g == Dict(false => [2, 4], true => [1, 3, 5])
        @test isconcretetype(eltype(g))
        @test axiskeys(g[false]) == ([6, 12],)
        @test g[false](a=6) == 2
    end

    @testset "typedtable" begin
        xs = Table(a=3 .* [1, 2, 3, 4, 5])
        g = @inferred group(x -> isodd(x.a), xs)
        @test g == Dict(false => [(a=6,), (a=12,)], true => [(a=3,), (a=9,), (a=15,)])
        @test isconcretetype(eltype(g))
        @test g[false].a == [6, 12]

        g = @inferred groupview(x -> isodd(x.a), xs)
        @test g == Dict(false => [(a=6,), (a=12,)], true => [(a=3,), (a=9,), (a=15,)])
        @test isconcretetype(eltype(g))
        @test g[false].a == [6, 12]
    end

    @testset "dictionary" begin
        Base.similar(d::AbstractDictionary, dims::Base.OneTo) = similar(Vector{valtype(d)}, dims)

        xs = dictionary(3 .* [1, 2, 3, 4, 5] .=> 1:5)
        g = @inferred group(isodd, xs)
        @test g == Dict(false => [2, 4], true => [1, 3, 5])
        @test isconcretetype(eltype(g))
        @test g[false] == [2, 4]

        # view(dct, range) doesn't work for dictionaries
        # g = @inferred groupview(isodd, xs)
        # @test g == Dict(false => [2, 4], true => [1, 3, 5])
        # @test isconcretetype(eltype(g))
        # @test g[false] == [2, 4]
        # xs[6] = 123
        # @test g == Dict(false => [123, 4], true => [1, 3, 5])
    end
end

@testset "filterview" begin
    a = [1, 2, 3]
    fv = @inferred(filterview(x -> x >= 2, a))
    @test fv == [2, 3]
    # ensure we get a view
    fv[1] = 10
    @test a == [1, 10, 3]

    a = Dict(1 => :a, 2 => :b, 3 => :c)
    fv = @inferred filterview(((k, v),) -> k == 2 || v == :c, a)
    @test fv == Dict(2 => :b, 3 => :c)
    @test length(fv) == 2
    @test !isempty(fv)
    @test fv[2] == :b
    @test_throws "key 1 not found" fv[1]
    @test collect(keys(fv)) == [2, 3]
    @test collect(values(fv)) == [:b, :c]
end

# @testset "(un)nest" begin
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

# @testset "vcat" begin
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


import CompatHelperLocal as CHL
CHL.@check()
