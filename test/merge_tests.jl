
@testset "merge tests" begin
    rng = StableRNG(43)
    iters = (1:2, 3:10)
    reps = 10^5
    size = 2
    for (m1, m2) in [(algRSWRSKIP, algRSWRSKIP)]
        res = zeros(Int, 10, 10)
        for _ in 1:reps
            s1 = ReservoirSample(rng, Int, size, m1)
            s2 = ReservoirSample(rng, Int, size, m2)
            s_all = (s1, s2)
            for (s, it) in zip(s_all, iters)
                for x in it
                    update!(s, x)
                end
            end
            s_merged = merge(s1, s2)
            res[value(s_merged)...] += 1
        end
        cases = m1 == algRSWRSKIP ? 10^size : factorial(10)/factorial(10-size)
        ps_exact = [1/cases for _ in 1:cases]
        count_est = vec(res)
        chisq_test = ChisqTest(count_est, ps_exact)
        @test pvalue(chisq_test) > 0.05
    end
    s1 = ReservoirSample(rng, Int, 2, algRSWRSKIP)
    s2 = ReservoirSample(rng, Int, 2, algRSWRSKIP)
    s_all = (s1, s2)
    for (s, it) in zip(s_all, iters)
        for x in it
            update!(s, x)
        end
    end
    @test length(value(merge!(s1, s2))) == 2
    s1 = ReservoirSample(rng, Int, algR)
    s2 = ReservoirSample(rng, Int, algR)
    update!(s1, 1)
    update!(s2, 2)
    @test value(merge!(s1, s2)) in (1, 2)
end
