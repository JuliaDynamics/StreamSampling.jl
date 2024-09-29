
using BenchmarkTools
using Distributions
using HypothesisTests
using Printf
using Random
using StableRNGs
using Test

using StreamSampling

@testset "StreamSampling.jl Tests" begin
    include("package_sanity_tests.jl")
    include("unweighted_sampling_single_tests.jl")
    include("unweighted_sampling_multi_tests.jl")
    include("weighted_sampling_single_tests.jl")
    include("weighted_sampling_multi_tests.jl")
    include("merge_tests.jl")
    include("benchmark/benchmark_tests.jl")
end