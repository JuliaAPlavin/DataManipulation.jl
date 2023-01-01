using ArraysExtra
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
end


import CompatHelperLocal as CHL
CHL.@check()
