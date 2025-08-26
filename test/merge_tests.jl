
@testset "merge/merge! tests" begin
    rng = StableRNG(43)
    iters = (1:2, 3:10)
    reps = 10^5
    size = 2
    for (m1, m2) in [(AlgRSWRSKIP(), AlgRSWRSKIP()), 
                     (AlgWRSWRSKIP(), AlgWRSWRSKIP()), 
                     (AlgARes(), AlgARes()), 
                     (AlgAExpJ(), AlgAExpJ())]
        res = zeros(Int, 10, 10)
        for _ in 1:reps
            s1 = ReservoirSampler{Int}(rng, size, m1)
            s2 = ReservoirSampler{Int}(rng, size, m2)
            s_all = (s1, s2)
            for (s, it) in zip(s_all, iters)
                for x in it
                    # Handle unweighted vs weighted algorithms
                    if m1 == AlgRSWRSKIP()
                        fit!(s, x)
                    else
                        fit!(s, x, 1.0)
                    end
                end
            end
            s_merged = merge(s1, s2)
            res[shuffle!(rng, value(s_merged))...] += 1
        end
        # Adjust expected number of cases for different algorithms
        if m1 == AlgRSWRSKIP() || m1 == AlgWRSWRSKIP()
            cases = 10^size
        else
            cases = factorial(10)/factorial(10-size)
        end
        ps_exact = [1/cases for _ in 1:cases]
        count_est = [x for x in vec(res) if x != 0]
        chisq_test = ChisqTest(count_est, ps_exact)
        @test pvalue(chisq_test) > 0.05
    end
    
    # Separate basic tests for AlgR and AlgL (not statistical)
    @testset "AlgR and AlgL basic merge tests" begin
        for m in (AlgR(), AlgL())
            s1 = ReservoirSampler{Int}(rng, size, m)
            s2 = ReservoirSampler{Int}(rng, size, m)
            
            # Add some data
            for x in 1:2; fit!(s1, x); end
            for x in 3:4; fit!(s2, x); end
            
            # Test that merge works
            merged = merge(s1, s2)
            @test merged isa Union{StreamSampling.MultiAlgRSampler_Mut, StreamSampling.MultiAlgLSampler_Mut}
            @test merged.n == size
            
            # Test that merge! works
            s3 = ReservoirSampler{Int}(rng, size, m)
            s4 = ReservoirSampler{Int}(rng, size, m)
            for x in 5:6; fit!(s3, x); end
            for x in 7:8; fit!(s4, x); end
            
            result = merge!(s3, s4)
            @test result === s3
        end
    end
    s1 = ReservoirSampler{Int}(rng, 2, AlgRSWRSKIP())
    s2 = ReservoirSampler{Int}(rng, 2, AlgRSWRSKIP())
    s_all = (s1, s2)
    for (s, it) in zip(s_all, iters)
        for x in it
            fit!(s, x)
        end
    end
    @test length(value(merge!(s1, s2))) == 2
    for m in (AlgRSWRSKIP(), AlgWRSWRSKIP())
        s1 = ReservoirSampler{Int}(rng, m)
        s2 = ReservoirSampler{Int}(rng, m)
        if m == AlgRSWRSKIP()
            fit!(s1, 1)
            fit!(s2, 2)
        else
            fit!(s1, 1, 1.0)
            fit!(s2, 2, 1.0)
        end
        @test value(merge!(s1, s2)) in (1, 2)
    end
    
    # Test merge! for multi-element unweighted samplers (AlgR and AlgL)
    for m in (AlgR(), AlgL())
        s1 = ReservoirSampler{Int}(rng, 1, m)  # Single element reservoir
        s2 = ReservoirSampler{Int}(rng, 1, m)
        fit!(s1, 1)
        fit!(s2, 2)
        result = value(merge!(s1, s2))
        @test length(result) == 1 && result[1] in (1, 2)
    end
end
