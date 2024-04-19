
@testset "Weighted sampling single tests" begin
    @testset "method=$method" for method in (algARes, algAExpJ)
    	wv(el) = 1.0
        a, b = 1, 100
        z = itsample(a:b, wv)
        @test a <= z <= b
        z = itsample(Iterators.filter(x -> x != b+1, a:b+1), wv)
        @test a <= z <= b
        rng = StableRNG(43)
        wv2(el) = el <= 50 ? 1.0 : 2.0
        iters = (a:b, Iterators.filter(x -> x != b + 1, a:b+1))
        for it in iters
            reps = 10000
            dict_res = Dict{Int, Int}()
            for _ in 1:reps
                s = itsample(rng, it, wv2)
                if s in keys(dict_res)
                    dict_res[s] += 1
                else
                    dict_res[s] = 1
                end
            end
            cases = 100
            ps_exact = [wv2(el)/150 for el in keys(dict_res)]

            count_est = collect(values(dict_res))

            chisq_test = ChisqTest(count_est, ps_exact)
            @test pvalue(chisq_test) > 0.05
        end
    end
end
