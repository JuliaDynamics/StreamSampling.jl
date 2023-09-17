
@testset "Unweighted sampling multi tests" begin
	@testset "alloc=$(alloc)" for alloc in [false, true]

		# test values are inrange
		a, b = 1, 10
		s = itsample(a:b, 2, alloc=alloc)
		@test length(s) == 2
		@test all(x -> a <= x <= b, s)
		@test typeof(s) == Any
		s = itsample(a:b, 2, alloc=alloc, iter_type=Int)
		@test length(s) == 2
		@test all(x -> a <= x <= b, s)
		@test typeof(s) == Int
		s = itsample(a:b, 100, alloc=alloc)
		@test length(s) == 10
		@test length(unique(s)) == 10

		# test values are random
		reps = 10000
		dict_res = Dict{Vector, Int}()
		for _ in 1:reps
			s = itsample(a:b, 2, alloc=alloc)
			if s in dict_res
				dict_res[s] += 1
			else
				dict_res[s] = 1
			end
		end
		p_exact = 1 / (10 * 9)
		ps_est = collect(values(dict_res)) ./ reps
		alpha = 0.01
		z_val = cdf(Normal(), 1-alpha/2)
		conf_int = z_val * sqrt.((ps_est .* (1 .- ps_est)) ./ reps)
		ps_est_l = ps_est .- conf_int
		ps_est_r = ps_est .+ conf_int

		count_p_exact_in = count(ps_est_l < p_exact < ps_est_r, reps)
		print(count_p_exact_in)
	end
end