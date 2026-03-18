
@testset "SequentialSampler tests" begin
    rng = StableRNG(42)
    N = 10
    n = 2
    reps = 10000

    for alg in (AlgD(), AlgHiddenShuffle())
        s = SequentialSampler(rng, n, N, alg)
        out = collect(s)
        @test length(out) == n
        @test issorted(out)
        @test allunique(out)
        @test all(1 .<= out .<= N)

        dict_res = Dict{Vector{Int}, Int}()
        for _ in 1:reps
            s = SequentialSampler(rng, n, N, alg)
            out = collect(s)
            dict_res[out] = get(dict_res, out, 0) + 1
        end

        valid_couples = 0
        for i in 1:N, j in i+1:N
            valid_couples += 1
        end
        
        count_est = Int[]
        for i in 1:N, j in i+1:N
            push!(count_est, get(dict_res, [i, j], 0))
        end
        
        chisq_test = ChisqTest(count_est, fill(1/valid_couples, valid_couples))
        @test pvalue(chisq_test) > 0.05
    end

    s = SequentialSampler(rng, n, N, AlgORDSWR())
    out = collect(s)
    @test length(out) == n
    @test issorted(out)
    @test all(1 .<= out .<= N)

    dict_res = Dict{Vector{Int}, Int}()
    for _ in 1:reps
        s = SequentialSampler(rng, n, N, AlgORDSWR())
        out = collect(s)
        dict_res[out] = get(dict_res, out, 0) + 1
    end

    count_est = Int[]
    ps_exact = Float64[]
    
    for i in 1:N, j in i:N
        push!(count_est, get(dict_res, [i, j], 0))
        if i == j
            push!(ps_exact, 1/(N^2))
        else
            push!(ps_exact, 2/(N^2))
        end
    end
    
    chisq_test = ChisqTest(count_est, ps_exact)
    @test pvalue(chisq_test) > 0.05
end
