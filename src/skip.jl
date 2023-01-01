materialize_views(s::Skip) = collect(s)
Base.getproperty(A::Skip, p::Symbol) = mapview(Accessors.PropertyLens(p), A)
Base.getproperty(A::Skip, p) = mapview(Accessors.PropertyLens(p), A)


@testitem "skip" begin
    a = StructArray(a=[missing, -1, 2, 3])
    sa = @inferred skip(x -> ismissing(x.a) || x.a < 0, a)
    @test collect(sa.a) == [2, 3]
end