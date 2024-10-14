

@testset "Unweighted sampling multi tests" begin
    combs = Iterators.product([(AlgL(), AlgR(), AlgRSWRSKIP()), (false, true)]...)
    @testset "method=$method ordered=$ordered" for (method, ordered) in combs
        a, b = 1, 10
        # test return values of iter with known lengths are inrange
        iter = a:b
        s = itsample(iter, 2, method; ordered=ordered)
        @test length(s) == 2
        @test all(x -> a <= x <= b, s)

        s = itsample(iter, 10^7, method; ordered=ordered)
        @test method == AlgRSWRSKIP() ? length(s) == 10^7 : length(s) == 10
        @test length(unique(s)) == 10
        @test all(x -> a <= x <= b, s)

        @test typeof(s) == Vector{Int}
        s = itsample(iter, 2, method; ordered=ordered)
        @test length(s) == 2
        @test all(x -> a <= x <= b, s)
        @test typeof(s) == Vector{Int}
        s = itsample(iter, 100, method; ordered=ordered)
        @test method == AlgRSWRSKIP() ? length(s) == 100 : length(s) == 10
        @test length(unique(s)) == 10

        # test return values of iter with unknown lengths are inrange
        iter = Iterators.filter(x -> x < 5, a:b)
        s = itsample(iter, 2, method; ordered=ordered)
        @test length(s) == 2
        @test all(x -> a <= x <= b, s)

        @test typeof(s) == Vector{Int}
        s = itsample(iter, 2, method; ordered=ordered)
        @test length(s) == 2
        @test all(x -> a <= x <= b, s)
        @test typeof(s) == Vector{Int}
        s = itsample(iter, 100, method; ordered=ordered)
        @test method == AlgRSWRSKIP() ? length(s) == 100 : length(s) == 4
        @test length(unique(s)) == 4
        @test ordered ? issorted(s) : true

        iter = Iterators.filter(x -> x != b + 1, a:b+1)
        rs = ReservoirSample{Int}(5, method; ordered = ordered)
        for x in iter
            fit!(rs, x)
        end
        @test length(value(rs)) == 5
        @test all(x -> a <= x <= b, value(rs))
        @test nobs(rs) == 10

        rngs = (StableRNG(41), StableRNG(40))
        iters = (a:b, Iterators.filter(x -> x != b + 1, a:b+1), (a:floor(Int, b/2), (floor(Int, b/2)+1):b))
        sizes = (2, 3)
        for it in iters
            for size in sizes
                reps = 10^(size+2)
                dict_res = Dict{Vector, Int}()
                for _ in 1:reps
                    if typeof(it) <: Tuple
                        if method == AlgRSWRSKIP() && ordered == false
                            s = shuffle!(rngs[1], itsample(rngs, it, size))
                        else
                            break
                        end
                    else
                        s = shuffle!(rngs[1], itsample(rngs[1], it, size, method; ordered=ordered))
                    end
                    if s in keys(dict_res)
                        dict_res[s] += 1
                    else
                        dict_res[s] = 1
                    end
                end
                if !(typeof(it) <: Tuple) || (method == AlgRSWRSKIP() && ordered == false)
                    cases = method == AlgRSWRSKIP() ? 10^size : factorial(10)/factorial(10-size)
                    ps_exact = [1/cases for _ in 1:cases]
                    count_est = collect(values(dict_res))

                    chisq_test = ChisqTest(count_est, ps_exact)
                    @test pvalue(chisq_test) > 0.05
                end
            end
        end
    end
end
