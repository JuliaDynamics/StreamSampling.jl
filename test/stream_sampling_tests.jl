@testset "StreamSampler tests" begin
    rng = StableRNG(45)
    N = 10
    n = 3
    reps = 100000

    for alg in (AlgD(), AlgHiddenShuffle())
        dict_res = Dict{Vector{Int}, Int}()
        for _ in 1:reps
            s = StreamSampler{Int}(rng, 1:N, n, N, alg)
            out = collect(s)
            dict_res[out] = get(dict_res, out, 0) + 1
        end
        
        valid_triples = 120
        count_est = Int[]
        for i in 1:N, j in i+1:N, k in j+1:N
            push!(count_est, get(dict_res, [i, j, k], 0))
        end
        
        chisq_test = ChisqTest(count_est, fill(1/valid_triples, valid_triples))
        @test pvalue(chisq_test) > 0.05
    end

    dict_res = Dict{Vector{Int}, Int}()
    for _ in 1:reps
        s = StreamSampler{Int}(rng, 1:N, n, N, AlgORDSWR())
        out = collect(s)
        dict_res[out] = get(dict_res, out, 0) + 1
    end
    
    count_est = Int[]
    ps_exact = Float64[]
    for i in 1:N, j in i:N, k in j:N
        push!(count_est, get(dict_res, [i, j, k], 0))
        if i == j == k
            push!(ps_exact, 1/(N^3))
        elseif i == j || j == k
            push!(ps_exact, 3/(N^3))
        else
            push!(ps_exact, 6/(N^3))
        end
    end
    
    chisq_test = ChisqTest(count_est, ps_exact)
    @test pvalue(chisq_test) > 0.05

    weights = [i <= 5 ? 1.0 : 2.0 for i in 1:N]
    W = sum(weights)
    wfunc(i) = weights[i]
    
    dict_res = Dict{Vector{Int}, Int}()
    for _ in 1:reps
        s = StreamSampler{Int}(rng, 1:N, wfunc, n, W, AlgORDWSWR())
        out = collect(s)
        dict_res[out] = get(dict_res, out, 0) + 1
    end
    
    count_est = Int[]
    ps_exact = Float64[]
    for i in 1:N, j in i:N, k in j:N
        push!(count_est, get(dict_res, [i, j, k], 0))
        wi, wj, wk = weights[i], weights[j], weights[k]
        if i == j == k
            push!(ps_exact, (wi^3) / (W^3))
        elseif i == j
            push!(ps_exact, 3 * (wi^2 * wk) / (W^3))
        elseif j == k
            push!(ps_exact, 3 * (wi * wj^2) / (W^3))
        else
            push!(ps_exact, 6 * (wi * wj * wk) / (W^3))
        end
    end
    
    chisq_test = ChisqTest(count_est, ps_exact)
    @test pvalue(chisq_test) > 0.05
end
