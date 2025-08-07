
function prob_replace(k)
    num = 1
    for x in k
        v = x <= 5 ? 1 : 2
        num *= v
    end
    return num/15^length(k)
end

function prob_no_replace(k)
	num = 1
	den = 1
	m = 0
	for x in k
		v = x <= 5 ? 1 : 2
		num *= v
		den *= (15 - m)
		m += v
	end
	if num == 2 && (den == 15*14 || den == 15*13)
		num = 9
		den = 910
	end
	return num/den
end

@testset "Weighted sampling multi tests" begin
    combs = Iterators.product([(AlgAExpJ(), AlgARes(), AlgWRSWRSKIP()), (false, true)]...)
    @testset "method=$method ordered=$ordered" for (method, ordered) in combs
        a, b = 1, 10
        # test return values of iter with known lengths are inrange
        weight(el) = 1.0
        iter = a:b
        s = itsample(iter, weight, 2, method; ordered=ordered)
        @test length(s) == 2
        @test all(x -> a <= x <= b, s)

        s = itsample(iter, weight, 10^7, method; ordered=ordered)
        @test method == AlgWRSWRSKIP() ? length(s) == 10^7 : length(s) == 10
        @test length(unique(s)) == 10
        @test all(x -> a <= x <= b, s)

        @test typeof(s) == Vector{Int}
        s = itsample(iter, weight, 2, method; ordered=ordered)
        @test length(s) == 2
        @test all(x -> a <= x <= b, s)
        @test typeof(s) == Vector{Int}
        s = itsample(iter, weight, 100, method; ordered=ordered)
        @test method == AlgWRSWRSKIP() ? length(s) == 100 : length(s) == 10
        @test length(unique(s)) == 10

        # test return values of iter with unknown lengths are inrange
        iter = Iterators.filter(x -> x < 5, a:b)
        s = itsample(iter, weight, 2, method; ordered=ordered)
        @test length(s) == 2
        @test all(x -> a <= x <= b, s)

        @test typeof(s) == Vector{Int}
        s = itsample(iter, weight, 2, method; ordered=ordered)
        @test length(s) == 2
        @test all(x -> a <= x <= b, s)
        @test typeof(s) == Vector{Int}
        s = itsample(iter, weight, 100, method; ordered=ordered)
        @test method == AlgWRSWRSKIP() ? length(s) == 100 : length(s) == 4
        @test length(unique(s)) == 4
        @test ordered ? issorted(s) : true

        iter = Iterators.filter(x -> x != b + 1, a:b+1)
        rs = ReservoirSampler{Int}(5, method; ordered = ordered)
        for x in iter
            fit!(rs, x, weight(x))
        end
        @test length(value(rs)) == 5
        @test all(x -> a <= x <= b, value(rs))
        @test nobs(rs) == 10

        weight2(el) = el <= 5 ? 1.0 : 2.0
        weight3(el) = el <= 5 ? 1.0 : 2.0
        wfuncs = (weight2, weight3)
        rngs = (StableRNG(41), StableRNG(42))
        iters = (a:b, Iterators.filter(x -> x != b+1, a:b+1), (a:floor(Int, b/2), (floor(Int, b/2)+1):b))
        sizes = (1, 2)
        for it in iters
            for size in sizes
                reps = 10^(size+3)
                dict_res = Dict{Vector, Int}()
                for _ in 1:reps
                    if typeof(it) <: Tuple
                        if method == AlgWRSWRSKIP() && ordered == false
                            s = shuffle!(rngs[1], itsample(rngs, it, wfuncs, size))
                        else
                            break
                        end
                    else
                        s = shuffle!(rngs[1], itsample(rngs[1], it, wfuncs[1], size, method; ordered=ordered))
                    end
                    if s in keys(dict_res)
                        dict_res[s] += 1
                    else
                        dict_res[s] = 1
                    end
                end
                if !(typeof(it) <: Tuple) || (method == AlgWRSWRSKIP() && ordered == false)
                    cases = method == AlgWRSWRSKIP() ? 10^size : factorial(10)/factorial(10-size)
                    pairs_dict = collect(pairs(dict_res))
                    if method == AlgWRSWRSKIP()
                        ps_exact = [prob_replace(k) for (k, v) in pairs_dict]
                    else
                        ps_exact = [prob_no_replace(k) for (k, v) in pairs_dict if length(unique(k)) == size]
                    end
                    count_est = [v for (k, v) in pairs_dict]
                    chisq_test = ChisqTest(count_est, ps_exact)
                    @test pvalue(chisq_test) > 0.05
                end
            end
        end
    end
end
