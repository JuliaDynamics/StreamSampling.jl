
@testset "simple tests" begin
    @test 1 <= sum(SequentialSampler(1, 10)) <= 10
    @test 1 <= sum(SequentialSampler(1, 10, AlgHiddenShuffle())) <= 10
    @test length(combine([[1,2,3], [4,5]], [1.0, 2.0])) == 2
end
@testset "itsample interface" begin
    rng = StableRNG(55)
    @test all(1:1000) do _
        s = itsample(rng, 1:10, 5, AlgHiddenShuffle())
        length(s) == 5 && allunique(s)
    end
    @test issorted(itsample(rng, 1:10, 5, AlgHiddenShuffle(); ordered = true))
    for alg in (AlgD(), AlgHiddenShuffle(), AlgORDSWR())
        @test isempty(collect(SequentialSampler(rng, 0, 10, alg)))
        @test collect(SequentialSampler{Int}(rng, 1:10, 0, 10, alg)) == Int[]
    end
    @test itsample(rng, 1:10, 0) == Int[]
    iter = Iterators.filter(isodd, 1:10)
    @test itsample(iter, 2; iter_type = Float64) isa Vector{Float64}
    @test itsample(iter, x -> 1.0; iter_type = Float64) isa Float64
end