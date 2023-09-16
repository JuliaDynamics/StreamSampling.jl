
using IteratorSampling
using Test, StableRNGs

@testset "IteratorSampling.jl Tests" begin
	include("unweighted_sampling_single_tests.jl")
    include("unweighted_sampling_multi_tests.jl")
end