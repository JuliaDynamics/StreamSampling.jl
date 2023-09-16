
@testset "Unweighted sampling single tests" begin
	@testset "alloc=$(alloc)" for alloc in [false, true]
		a, b = 1, 100
		x = itsample(a:b; alloc=alloc)
		@test a <= x <= b
	end
end