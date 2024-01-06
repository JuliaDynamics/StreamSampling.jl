
@testset "Unweighted sampling multi tests" begin
	combs = Iterators.product(fill((true, false),2)...)
	@testset "replace=$replace ordered=$ordered" for (replace, ordered) in combs
		a, b = 1, 10
		# test return values of iter with known lengths are inrange
		iter = a:b
		s = itsample(iter, 2, replace=replace, ordered=ordered)
		@test length(s) == 2
		@test all(x -> a <= x <= b, s)

		@test typeof(s) == Vector{Int}
		s = itsample(iter, 2, replace=replace, ordered=ordered)
		@test length(s) == 2
		@test all(x -> a <= x <= b, s)
		@test typeof(s) == Vector{Int}
		s = itsample(iter, 100, replace=replace, ordered=ordered)
		@test replace ? length(s) == 100 : length(s) == 10
		@test length(unique(s)) == 10

		# test return values of iter with unknown lengths are inrange
		iter = Iterators.filter(x -> x < 5, a:b)
		s = itsample(iter, 2, replace=replace, ordered=ordered)
		@test length(s) == 2
		@test all(x -> a <= x <= b, s)

		@test typeof(s) == Vector{Int}
		s = itsample(iter, 2, replace=replace, ordered=ordered)
		@test length(s) == 2
		@test all(x -> a <= x <= b, s)
		@test typeof(s) == Vector{Int}
		s = itsample(iter, 100, replace=replace, ordered=ordered)
		@test replace ? length(s) == 100 : length(s) == 4
		@test length(unique(s)) == 4
		@test ordered ? issorted(s) : true

		# create empirical distribution
		iter = a:b
		rng = StableRNG(43)
		reps = 10000
		dict_res = Dict{Vector, Int}()
		for _ in 1:reps
			s = shuffle!(itsample(rng, iter, 2, replace=replace, ordered=ordered))
			if s in keys(dict_res)
				dict_res[s] += 1
			else
				dict_res[s] = 1
			end
		end
		cases = replace ? 10*10 : 10*9
		ps_exact = [1/cases for _ in 1:cases]
		count_est = collect(values(dict_res))

		# chi-squared test
		chisq_test = ChisqTest(count_est, ps_exact)
		@test pvalue(chisq_test) > 0.05
	end
end
