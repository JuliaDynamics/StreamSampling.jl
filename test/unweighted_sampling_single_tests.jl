
@testset "Unweighted sampling single tests" begin
    a, b = 1, 100
    z = itsample(a:b)
    @test a <= z <= b
    z = itsample(Iterators.filter(x -> x != b+1, a:b+1))
    @test a <= z <= b
    rng = StableRNG(43)
    iters = (a:b, Iterators.filter(x -> x != b + 1, a:b+1))
    for it in iters
        reps = 10000
        dict_res = Dict{Int, Int}()
        for _ in 1:reps
            s = itsample(rng, it)
            if s in keys(dict_res)
                dict_res[s] += 1
            else
                dict_res[s] = 1
            end
        end
        cases = 100
        ps_exact = [1/cases for _ in 1:cases]
        count_est = collect(values(dict_res))

        chisq_test = ChisqTest(count_est, ps_exact)
        @test pvalue(chisq_test) > 0.05
    end
end
