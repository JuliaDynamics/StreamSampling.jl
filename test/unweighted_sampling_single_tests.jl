
@testset "Unweighted sampling single tests" begin
	a, b = 1, 100
	z = itsample(a:b)
	@test a <= z <= b
	z = itsample(Iterators.filter(x -> x != 101, a:b+1))
	@test a <= z <= b
end
