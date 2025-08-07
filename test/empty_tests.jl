
@testset "empty! tests" begin
    rng = StableRNG(43)
	rs = ReservoirSampler{Int}(AlgRSWRSKIP())
	fit!(rs, 1)
	empty!(rs)
    @test value(rs) === nothing
    rs = ReservoirSampler{Int}(AlgWRSWRSKIP())
    fit!(rs, 1, 1.0)
	empty!(rs)
    @test value(rs) === nothing
    for m in (AlgR(), AlgL(), AlgRSWRSKIP())
	    rs = ReservoirSampler{Int}(1, m)
	    fit!(rs, 1)
	    empty!(rs)
    	@test value(rs) == Int64[]
    end
    for m in (AlgARes(), AlgAExpJ(), AlgWRSWRSKIP())
	    rs = ReservoirSampler{Int}(1, m)
	    fit!(rs, 1, 1.0)
	    empty!(rs)
    	@test value(rs) == Int64[]
    end
end