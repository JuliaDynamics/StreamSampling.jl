
using StreamSampling, StableRNGs, HypothesisTests, Random, Test

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
                    m1 == AlgRSWRSKIP() ? fit!(s, x) : fit!(s, x, 1.0)
                end
            end
            s_merged = merge(s1, s2)
            res[shuffle!(rng, value(s_merged))...] += 1
        end
        cases = (m1 == AlgRSWRSKIP() || m1 == AlgWRSWRSKIP()) ? 10^size : factorial(10)/factorial(10-size)
        ps_exact = [1/cases for _ in 1:cases]
        count_est = [x for x in vec(res) if x != 0]
        chisq_test = ChisqTest(count_est, ps_exact)
        @test pvalue(chisq_test) > 0.05
    end
    
    # Test basic merge functionality for AlgR and AlgL
    for alg in [AlgR(), AlgL()]
        s1 = ReservoirSampler{Int}(rng, 2, alg)
        s2 = ReservoirSampler{Int}(rng, 2, alg)
        
        # Test empty merge
        s_merged_empty = merge(s1, s2)
        @test length(value(s_merged_empty)) == 0
        
        # Test merge! for empty
        s_copy = ReservoirSampler{Int}(rng, 2, alg)
        s_other = ReservoirSampler{Int}(rng, 2, alg)
        s_merged_empty_mut = merge!(s_copy, s_other)
        @test s_merged_empty_mut === s_copy
        @test length(value(s_merged_empty_mut)) == 0
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
        m == AlgRSWRSKIP() ? fit!(s1, 1) : fit!(s1, 1, 1.0)
        m == AlgRSWRSKIP() ? fit!(s2, 2) : fit!(s2, 2, 1.0)
        @test value(merge!(s1, s2)) in (1, 2)
    end
end
