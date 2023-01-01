using TestItems
using TestItemRunner
@run_package_tests


@testitem "symbols" begin
    x = (a=123, def="c")
    @test :a(x) == 123
    @test S"def"(x) == "c"
end

@testitem "mutate" begin
    using ArraysExtra: MappedArray
    using StructArrays

    X = [(a=1, b=(c=2,)), (a=3, b=(c=4,))]
    @test mutate(x -> (c=x.a^2,), X) == [(a=1, b=(c=2,), c=1), (a=3, b=(c=4,), c=9)]
    @test mutate(x -> (a=x.a^2,), X) == [(a=1, b=(c=2,)), (a=9, b=(c=4,))]
    @test mutate(c=x -> x.a^2, X) == [(a=1, b=(c=2,), c=1), (a=3, b=(c=4,), c=9)]
    @test mutate(c=x -> x.a^2, d=x -> x.a + 1, X) == [(a=1, b=(c=2,), c=1, d=2), (a=3, b=(c=4,), c=9, d=4)]
    @test mutate(x -> (b=(d=x.a,),), X) == [(a=1, b=(d=1,)), (a=3, b=(d=3,))]

    Y = mutateview(c=x -> x.a^2, X)
    @test Y == [(a=1, b=(c=2,), c=1), (a=3, b=(c=4,), c=9)]
    @test @inferred(Y[1]) == (a=1, b=(c=2,), c=1)

    S = StructArray(X)
    Sm = mutate(c=x -> x.a^2, S)
    @test eltype(Sm) == @NamedTuple{a::Int, b::@NamedTuple{c::Int}, c::Int}
    @test Sm.a === S.a
    @test Sm.b === S.b
    @test Sm.c == [1, 9]

    Sm = mutateview(c=x -> x.a^2, S)
    @test eltype(Sm) == @NamedTuple{a::Int, b::@NamedTuple{c::Int}, c::Int}
    @test Sm.a === S.a
    @test Sm.b === S.b
    @test Sm.c::MappedArray == [1, 9]
end

@testitem "filterview" begin
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

@testitem "mapview" begin
    using ArraysExtra: MappedArray
    using AccessorsExtra

    @testset "array" begin
        a = [1, 2, 3]
        ma = @inferred mapview(@optic(_ + 1), a)
        @test ma == [2, 3, 4]
        @test ma isa AbstractVector{Int}
        @test @inferred(ma[3]) == 4
        @test @inferred(ma[CartesianIndex(3)]) == 4
        @test @inferred(ma[2:3])::MappedArray == [3, 4]
        @test @inferred(map(x -> x * 2, ma))::Vector{Int} == [4, 6, 8]
        @test reverse(ma)::MappedArray == [4, 3, 2]
        @test view(ma, 2:3)::SubArray == [3, 4]
        @test size(similar(typeof(ma), 3)::Vector{Int}) == (3,)
        
        # ensure we get a view
        a[2] = 20
        @test ma == [2, 21, 4]

        ma[3] = 11
        ma[1:2] = [21, 31]
        push!(ma, 101)
        @test a == [20, 30, 10, 100]
        @test ma == [21, 31, 11, 101]

        ma = @inferred mapview(x -> (; x=x + 1), a)
        @test ma.x::MappedArray{Int} == [21, 31, 11, 101]
        @test parent(ma.x) === parent(ma) === a

        # multiple arrays - not implemented
        # ma = @inferred mapview((x, y) -> x + y, 1:3, [10, 20, 30])
        # @test ma == [11, 22, 33]
        # @test @inferred(ma[2]) == 22
        # @test @inferred(ma[CartesianIndex(2)]) == 22

        @testset "find" begin
            ma = mapview(@optic(_ * 10), [1, 2, 2, 2, 3, 4])
            @test findfirst(==(30), ma) == 5
            @test findfirst(==(35), ma) |> isnothing
            @test searchsortedfirst(ma, 20) == 2
            @test searchsortedlast(ma, 20) == 4
            @test searchsortedfirst(reverse(ma), 20; rev=true) == 3
            @test searchsortedlast(reverse(ma), 20; rev=true) == 5

            ma = mapview(x -> x * 10, [1, 2, 2, 2, 3, 4])
            @test findfirst(==(30), ma) == 5
            @test findfirst(==(35), ma) |> isnothing
            @test searchsortedfirst(ma, 20) == 2
            @test searchsortedlast(ma, 20) == 4
            @test searchsortedfirst(reverse(ma), 20; rev=true) == 3
            @test searchsortedlast(reverse(ma), 20; rev=true) == 5

            ma = mapview(@optic(_ * -10), .- [1, 2, 2, 2, 3, 4])
            @test findfirst(==(30), ma) == 5
            @test findfirst(==(35), ma) |> isnothing
            @test searchsortedfirst(ma, 20) == 2
            @test searchsortedlast(ma, 20) == 4
            @test searchsortedfirst(reverse(ma), 20; rev=true) == 3
            @test searchsortedlast(reverse(ma), 20; rev=true) == 5
        end
    end

    @testset "dict" begin
        a = Dict(:a => 1, :b => 2, :c => 3)
        ma = @inferred mapview(@optic(_ + 1), a)
        @test ma == Dict(:a => 2, :b => 3, :c => 4)
        @test ma isa AbstractDict{Symbol, Int}
        @test @inferred(ma[:c]) == 4
        # ensure we get a view
        a[:b] = 20
        @test ma == Dict(:a => 2, :b => 21, :c => 4)

        ma[:c] = 11
        ma[:d] = 31
        @test a == Dict(:a => 1, :b => 20, :c => 10, :d => 30)
        @test ma == Dict(:a => 2, :b => 21, :c => 11, :d => 31)
    end

    @testset "iterator" begin
        a = [1, 2, 3]
        ma = @inferred mapview(x -> x + 1, (x for x in a))
        @test ma == [2, 3, 4]
        @test @inferred(eltype(ma)) == Int
        @test @inferred(first(ma)) == 2
        @test @inferred(collect(ma)) == [2, 3, 4]
        @test @inferred(findmax(ma)) == (4, 3)
        # ensure we get a view
        a[2] = 20
        @test ma == [2, 21, 4]
    end

    using Unitful
    @testset "range" begin
        @test maprange(identity, 1, 10, length=5) ≈ range(1, 10, length=5)
        lr = @inferred maprange(log10, 0.1, 10, length=5)
        @test lr ≈ [0.1, √0.1, 1, √10, 10]
        for f in [log, log2, log10,] # @optic(log(0.1, _))] XXX - see my fix PR to InverseFunctions
            lr = @inferred maprange(f, 0.1, 10, length=5)
            @test lr ≈ [0.1, √0.1, 1, √10, 10]
            lr = @inferred maprange(f, 10, 0.1, length=5)
            @test lr ≈ [0.1, √0.1, 1, √10, 10] |> reverse
        end

        lr = @inferred maprange(@optic(log(ustrip(u"m", _))), 0.1u"m", 10u"m", length=5)
        @test lr ≈ [0.1, √0.1, 1, √10, 10]u"m"
        lr = @inferred maprange(@optic(log(ustrip(u"m", _))), 10u"cm", 10u"m", length=5)
        @test lr ≈ [0.1, √0.1, 1, √10, 10]u"m"

        @testset for a in [1, 10, 100, 1000, 1e-10, 1e10], b in [1, 10, 100, 1000, 1e-10, 1e10], len in [2:10; 12345]
            rng = maprange(log, a, b, length=len)
            @test length(rng) == len
            a != b && @test allunique(rng)
            @test issorted(rng, rev=a > b)
            @test minimum(rng) == min(a, b)
            @test maximum(rng) == max(a, b)
        end
    end
end

@testitem "discreterange" begin
    using ArraysExtra: discreterange
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

    g = group(isodd, skip(isnothing, [1., 2, nothing, 3]))
    @test g == dictionary([true => [1, 3], false => [2]])
    @test g isa Dictionary{Bool, <:SubArray{Float64}}

    g = group(isodd, skip(isnan, [1, 2, NaN, 3]))
    @test g == dictionary([true => [1, 3], false => [2]])
    @test g isa Dictionary{Bool, <:SubArray{Float64}}

    g = groupfind(isodd, skip(isnan, [1, 2, NaN, 3]))
    @test g == dictionary([true => [1, 4], false => [2]])
    @test g isa Dictionary{Bool, <:SubArray{Int}}
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
    @test auv[ArraysExtra.inverseindices(auv)] == a

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
end

@testitem "sentinelview" begin
    A = [10, 20, 30]

    Av = sentinelview(A, [1, 3], nothing)
    @test Av == [10, 30]
    @test Av isa SubArray{Int}

    Av = sentinelview(A, Union{Int, Nothing}[1, 3], nothing)
    @test Av == [10, 30]
    @test Av isa AbstractArray{Union{Int, Nothing}}

    Av = sentinelview(A, [1, nothing, 3], nothing)
    @test Av == [10, nothing, 30]
    @test Av isa AbstractArray{Union{Int, Nothing}}

    @test_throws "incompatible" sentinelview(A, [1, missing, 3], nothing)
    @test_throws "incompatible" sentinelview(A, [1, 3], 0)
end

@testitem "materialize_views" begin
    using Dictionaries: dictionary, Dictionary

    @test materialize_views([10, 20, 30])::Vector{Int} == [10, 20, 30]
    @test materialize_views(view([10, 20, 30], [1, 2]))::Vector{Int} == [10, 20]
    @test materialize_views(filterview(x -> true, [10, 20, 30]))::Vector{Int} == [10, 20, 30]
    @test materialize_views(mapview(x -> 10x, [1, 2, 3]))::Vector{Int} == [10, 20, 30]
    @test materialize_views(skip(isnan, [10, 20, NaN]))::Vector{Float64} == [10, 20]
    @test materialize_views(sentinelview([10, 20, 30], [1, nothing, 3], nothing))::Vector{Union{Int, Nothing}} == [10, nothing, 30]
    @test materialize_views(group(isodd, 3 .* [1, 2, 3, 4, 5]))::Dictionary{Bool, Vector{Int}} == dictionary([true => [3, 9, 15], false => [6, 12]])
    @test materialize_views(group(isodd, 3 .* [1, 2, 3, 4, 5]; dicttype=Dict))::Dict{Bool, Vector{Int}} == Dict([true => [3, 9, 15], false => [6, 12]])
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
    Aqua.test_all(ArraysExtra; ambiguities=false)
    Aqua.test_ambiguities(ArraysExtra)

    import CompatHelperLocal as CHL
    CHL.@check()
end
