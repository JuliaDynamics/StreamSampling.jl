
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

@testset "Unweighted sampling multi tests" begin
    combs = [(false, false),]
    combs_with_m = []
    for c in combs
        push!(combs_with_m, (c..., :alg_ARes))
        push!(combs_with_m, (c..., :alg_AExpJ))
    end
    @testset "replace=$replace ordered=$ordered method=$method" for (replace, ordered, method) in combs_with_m
        a, b = 1, 10
        # test return values of iter with known lengths are inrange
        weight(el) = 1.0
        iter = a:b
        s = itsample(iter, weight, 2, replace=replace, ordered=ordered, method=method)
        @test length(s) == 2
        @test all(x -> a <= x <= b, s)

        s = itsample(iter, weight, 10^7, replace=replace, ordered=ordered, method=method)
        @test replace ? length(s) == 10^7 : length(s) == 10
        @test length(unique(s)) == 10
        @test all(x -> a <= x <= b, s)

        @test typeof(s) == Vector{Int}
        s = itsample(iter, weight, 2, replace=replace, ordered=ordered, method=method)
        @test length(s) == 2
        @test all(x -> a <= x <= b, s)
        @test typeof(s) == Vector{Int}
        s = itsample(iter, weight, 100, replace=replace, ordered=ordered, method=method)
        @test replace ? length(s) == 100 : length(s) == 10
        @test length(unique(s)) == 10

        # test return values of iter with unknown lengths are inrange
        iter = Iterators.filter(x -> x < 5, a:b)
        s = itsample(iter, weight, 2, replace=replace, ordered=ordered, method=method)
        @test length(s) == 2
        @test all(x -> a <= x <= b, s)

        @test typeof(s) == Vector{Int}
        s = itsample(iter, weight, 2, replace=replace, ordered=ordered, method=method)
        @test length(s) == 2
        @test all(x -> a <= x <= b, s)
        @test typeof(s) == Vector{Int}
        s = itsample(iter, weight, 100, replace=replace, ordered=ordered, method=method)
        @test replace ? length(s) == 100 : length(s) == 4
        @test length(unique(s)) == 4
        @test ordered ? issorted(s) : true

        weight2(el) = el <= 5 ? 1.0 : 2.0
        rng = StableRNG(43)
        iters = (a:b, Iterators.filter(x -> x != b+1, a:b+1))
        sizes = (1, 2)
        for it in iters
            for size in sizes
                reps = 10^(size+3)
                dict_res = Dict{Vector, Int}()
                for _ in 1:reps
                    s = shuffle!(rng, itsample(rng, it, weight2, size, replace=replace, ordered=ordered, method=method))
                    if s in keys(dict_res)
                        dict_res[s] += 1
                    else
                        dict_res[s] = 1
                    end
                end
                cases = replace ? 10^size : factorial(10)/factorial(10-size)
                pairs_dict = collect(pairs(dict_res))
                ps_exact = [prob_no_replace(k) for (k, v) in pairs_dict if length(unique(k)) == size]
                count_est = [v for (k, v) in pairs_dict]
                chisq_test = ChisqTest(count_est, ps_exact)
                @test pvalue(chisq_test) > 0.05
            end
        end
    end
end
