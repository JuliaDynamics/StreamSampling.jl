
@testset "empty! tests" begin
    rng = StableRNG(43)
	rs = ReservoirSample{Int}(AlgRSWRSKIP())
	fit!(rs, 1)
	empty!(rs)
    @test value(rs) === nothing
    rs = ReservoirSample{Int}(AlgWRSWRSKIP())
    fit!(rs, 1, 1.0)
	empty!(rs)
    @test value(rs) === nothing
    for m in (AlgR(), AlgL(), AlgRSWRSKIP())
	    rs = ReservoirSample{Int}(1, m)
	    fit!(rs, 1)
	    empty!(rs)
    	@test value(rs) == Int64[]
    end
    for m in (AlgARes(), AlgAExpJ(), AlgWRSWRSKIP())
	    rs = ReservoirSample{Int}(1, m)
	    fit!(rs, 1, 1.0)
	    empty!(rs)
    	@test value(rs) == Int64[]
    end
end