
@testset "simple tests" begin
    @test 1 <= sum(SequentialSampler(1, 10)) <= 10
    @test 1 <= sum(SequentialSampler(1, 10, AlgHiddenShuffle())) <= 10
    @test length(combine([[1,2,3], [4,5]], [1.0, 2.0])) == 2
end