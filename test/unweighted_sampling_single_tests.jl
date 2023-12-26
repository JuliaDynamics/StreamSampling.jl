
@testset "Unweighted sampling single tests" begin
	a, b = 1, 100
	x = itsample(a:b)
	@test a <= x <= b
end