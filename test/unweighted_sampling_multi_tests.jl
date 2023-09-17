
@testset "Unweighted sampling multi tests" begin
	@testset "alloc=$(alloc)" for alloc in [false, true]

		# test values are inrange
		a, b = 1, 10
		s = itsample(a:b, 2, alloc=alloc)
		@test length(s) == 2
		@test all(x -> a <= x <= b, s)

		@test typeof(s) == Vector{ifelse(alloc, Int, Any)}
		s = itsample(a:b, 2, alloc=alloc, iter_type=Int)
		@test length(s) == 2
		@test all(x -> a <= x <= b, s)
		@test typeof(s) == Vector{Int}
		s = itsample(a:b, 100, alloc=alloc)
		@test length(s) == 10
		@test length(unique(s)) == 10

		# test values are random
		rng = MersenneTwister(42)
		reps = 100000
		dict_res = Dict{Vector, Int}()
		for _ in 1:reps
			s = itsample(rng, a:b, 2, alloc=alloc)
			if s in keys(dict_res)
				dict_res[s] += 1
			elseif ifelse(alloc, Int, Any)[s[2], s[1]] in keys(dict_res)
				dict_res[ifelse(alloc, Int, Any)[s[2], s[1]]] += 1
			else
				dict_res[s] = 1
			end
		end
		p_exact = 1 / (10 * 9)
		println(dict_res)
		println(length(dict_res))
		ps_est = collect(values(dict_res)) ./ reps
		alpha = 0.05
		z_val = cdf(Normal(), 1-alpha/2)
		conf_int = z_val * sqrt.((ps_est .* (1 .- ps_est)) ./ reps)
		ps_est_l = ps_est .- conf_int
		ps_est_r = ps_est .+ conf_int
		intervals = zip(ps_est_l, ps_est_r)
		count_p_exact_in = count(i -> i[1] < p_exact < i[2], intervals)
		println(count_p_exact_in)
	end
end