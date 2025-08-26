using StreamSampling
using Test
using Random

@testset "AlgR and AlgL merge/merge! tests" begin
    rng = Random.default_rng()
    Random.seed!(rng, 43)
    
    # Test that merge functions don't error out
    @testset "Basic merge functionality" begin
        s1 = ReservoirSampler{Int}(rng, 2, AlgR())
        s2 = ReservoirSampler{Int}(rng, 2, AlgR())
        
        # The merge should work even with empty samplers
        merged = merge(s1, s2)
        @test merged isa StreamSampling.MultiAlgRSampler_Mut
        @test merged.n == 2
        
        # Test merge! 
        s3 = ReservoirSampler{Int}(rng, 2, AlgR())
        s4 = ReservoirSampler{Int}(rng, 2, AlgR())
        result = merge!(s3, s4)
        @test result === s3  # merge! should return the first sampler
        @test s3.n == 2
    end
    
    @testset "AlgL merge functionality" begin
        s1 = ReservoirSampler{Int}(rng, 2, AlgL())
        s2 = ReservoirSampler{Int}(rng, 2, AlgL())
        
        merged = merge(s1, s2)
        @test merged isa StreamSampling.MultiAlgLSampler_Mut
        @test merged.n == 2
        @test merged.state == 0.0  # Should be reset
        @test merged.skip_k == 0   # Should be reset
        
        # Test merge!
        s3 = ReservoirSampler{Int}(rng, 2, AlgL())
        s4 = ReservoirSampler{Int}(rng, 2, AlgL())
        result = merge!(s3, s4)
        @test result === s3
        @test s3.state == 0.0
        @test s3.skip_k == 0
    end
    
    # Test that merge functions preserve minimum n
    @testset "Minimum n preservation" begin
        s1 = ReservoirSampler{Int}(rng, 3, AlgR())
        s2 = ReservoirSampler{Int}(rng, 2, AlgR())
        merged = merge(s1, s2)
        @test merged.n == 2  # Should take minimum
        
        s3 = ReservoirSampler{Int}(rng, 3, AlgL())
        s4 = ReservoirSampler{Int}(rng, 2, AlgL())
        merged = merge(s3, s4)
        @test merged.n == 2
    end
    
    # Test merge! error conditions
    @testset "merge! error conditions" begin
        s1 = ReservoirSampler{Int}(rng, 3, AlgR())  # bigger
        s2 = ReservoirSampler{Int}(rng, 2, AlgR())  # smaller
        
        @test_throws ErrorException merge!(s1, s2)  # Should error because s1.n > s2.n
        
        s3 = ReservoirSampler{Int}(rng, 3, AlgL())
        s4 = ReservoirSampler{Int}(rng, 2, AlgL())
        
        @test_throws ErrorException merge!(s3, s4)
    end
end

println("Basic merge tests completed successfully!")