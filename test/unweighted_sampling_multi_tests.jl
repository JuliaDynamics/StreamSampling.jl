
@testset "Unweighted sampling multi tests" begin
	@testset "alloc=$(alloc)" for alloc in [false, true]
		a, b = 1, 100
		s = itsample(a:b, 10, alloc=alloc)
		@test all(x -> a <= x <= b, s)
		s = itsample(a:b, 200, alloc=alloc)
		@test length(s) == 100
		@test length(unique(s)) == 100
	end
end