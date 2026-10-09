
@testset "merge/merge! tests" begin
    rng = StableRNG(47)
    iters = (1:2, 3:10)
    reps = 10^5
    size = 2
    for (m1, m2) in [(AlgRSWRSKIP(), AlgRSWRSKIP()), 
                     (AlgWRSWRSKIP(), AlgWRSWRSKIP()), 
                     (AlgARes(), AlgARes()), 
                     (AlgAExpJ(), AlgAExpJ())]
        res = zeros(Int, 10, 10)
        for _ in 1:reps
            s1 = ReservoirSampler{Int}(rng, size, m1)
            s2 = ReservoirSampler{Int}(rng, size, m2)
            s_all = (s1, s2)
            for (s, it) in zip(s_all, iters)
                for x in it
                    m1 == AlgRSWRSKIP() ? fit!(s, x) : fit!(s, x, 1.0)
                end
            end
            s_merged = merge(s1, s2)
            res[shuffle!(rng, value(s_merged))...] += 1
        end
        cases = (m1 == AlgRSWRSKIP() || m1 == AlgWRSWRSKIP()) ? 10^size : factorial(10)/factorial(10-size)
        ps_exact = [1/cases for _ in 1:cases]
        count_est = [x for x in vec(res) if x != 0]
        chisq_test = ChisqTest(count_est, ps_exact)
        @test pvalue(chisq_test) > 0.05
    end
    s1 = ReservoirSampler{Int}(rng, 2, AlgRSWRSKIP())
    s2 = ReservoirSampler{Int}(rng, 2, AlgRSWRSKIP())
    s_all = (s1, s2)
    for (s, it) in zip(s_all, iters)
        for x in it
            fit!(s, x)
        end
    end
    @test length(value(merge!(s1, s2))) == 2
    for m in (AlgRSWRSKIP(), AlgWRSWRSKIP())
        s1 = ReservoirSampler{Int}(rng, m)
        s2 = ReservoirSampler{Int}(rng, m)
        m == AlgRSWRSKIP() ? fit!(s1, 1) : fit!(s1, 1, 1.0)
        m == AlgRSWRSKIP() ? fit!(s2, 2) : fit!(s2, 2, 1.0)
        @test value(merge!(s1, s2)) in (1, 2)
    end

    iters = (1:10, 11:30)
    reps = 10000
    for m in (AlgRSWRSKIP(),)
        count_s1 = 0
        for _ in 1:reps
            s1 = ReservoirSampler{Int}(rng, m)
            s2 = ReservoirSampler{Int}(rng, m)
            for x in iters[1] fit!(s1, x) end
            for x in iters[2] fit!(s2, x) end
            s_merged = merge(s1, s2)
            if value(s_merged) <= 10
                count_s1 += 1
            end
        end
        chisq_test = ChisqTest([count_s1, reps - count_s1], [1/3, 2/3])
        @test pvalue(chisq_test) > 0.05
    end

    for m in (AlgWRSWRSKIP(),)
        count_s1 = 0
        for _ in 1:reps
            s1 = ReservoirSampler{Int}(rng, m)
            s2 = ReservoirSampler{Int}(rng, m)
            for x in iters[1] fit!(s1, x, 1.0) end
            for x in iters[2] fit!(s2, x, 1.0) end
            s_merged = merge(s1, s2)
            if value(s_merged) <= 10
                count_s1 += 1
            end
        end
        chisq_test = ChisqTest([count_s1, reps - count_s1], [1/3, 2/3])
        @test pvalue(chisq_test) > 0.05
        
        rng = StableRNG(45)
        count_s1 = 0
        for _ in 1:reps
            s1 = ReservoirSampler{Int}(rng, m)
            s2 = ReservoirSampler{Int}(rng, m)
            fit!(s1, 1, 10.0)
            fit!(s2, 2, 20.0)
            s_merged = merge(s1, s2)
            if value(s_merged) == 1
                count_s1 += 1
            end
         end
         chisq_test = ChisqTest([count_s1, reps - count_s1], [1/3, 2/3])
         @test pvalue(chisq_test) > 0.05
    end
end

is_weighted(m) = m isa Union{AlgWRSWRSKIP, AlgARes, AlgAExpJ}
upd!(s, m, x) = is_weighted(m) ? fit!(s, x, 1.0) : fit!(s, x)

@testset "fit! after merge/merge!" begin
    rng = StableRNG(53)
    reps = 10^5
    iters, rest, N = (1:5, 6:10), 11:15, 15
    function merged_sampler(f, m, args...)
        s1 = ReservoirSampler{Int}(rng, args..., m)
        s2 = ReservoirSampler{Int}(rng, args..., m)
        for x in iters[1] upd!(s1, m, x) end
        for x in iters[2] upd!(s2, m, x) end
        s = f(s1, s2)
        for x in rest upd!(s, m, x) end
        return s
    end
    for f in (merge, merge!)
        for m in (AlgRSWRSKIP(), AlgWRSWRSKIP())
            counts = zeros(Int, N)
            for _ in 1:reps
                counts[value(merged_sampler(f, m))] += 1
            end
            @test pvalue(ChisqTest(counts, fill(1/N, N))) > 0.001
            counts = zeros(Int, N)
            for _ in 1:reps
                for x in value(merged_sampler(f, m, 2)) counts[x] += 1 end
            end
            @test pvalue(ChisqTest(counts, fill(1/N, N))) > 0.001
        end
        for m in (AlgARes(), AlgAExpJ())
            counts = Dict{Vector{Int}, Int}()
            for _ in 1:reps
                k = sort(value(merged_sampler(f, m, 2)))
                counts[k] = get(counts, k, 0) + 1
            end
            pairs_all = [[i, j] for i in 1:N for j in i+1:N]
            count_est = [get(counts, k, 0) for k in pairs_all]
            @test pvalue(ChisqTest(count_est, fill(1/length(pairs_all), length(pairs_all)))) > 0.001
        end
    end
end

@testset "merge/merge! keep the reservoir size" begin
    rng = StableRNG(54)
    for m in (AlgARes(), AlgAExpJ()), f in (merge, merge!)
        s1, s2 = ReservoirSampler{Int}(rng, 3, m), ReservoirSampler{Int}(rng, 3, m)
        fit!(s1, 1, 1.0)
        for x in 2:10 fit!(s2, x, 1.0) end
        v = value(f(s1, s2))
        @test length(v) == 3 && allunique(v) && all(in(1:10), v)
        s1, s2 = ReservoirSampler{Int}(rng, 3, m), ReservoirSampler{Int}(rng, 3, m)
        fit!(s1, 1, 1.0)
        fit!(s2, 2, 1.0)
        @test sort(value(f(s1, s2))) == [1, 2]
    end
    for m in (AlgRSWRSKIP(), AlgWRSWRSKIP()), f in (merge, merge!)
        s1, s2 = ReservoirSampler{Int}(rng, 3, m), ReservoirSampler{Int}(rng, 3, m)
        for x in 1:10 upd!(s2, m, x) end
        v = value(f(s1, s2))
        @test length(v) == 3 && all(in(1:10), v)
    end
    for m in (AlgARes(), AlgAExpJ())
        s1, s2 = ReservoirSampler{Int}(rng, 2, m; ordered = true), ReservoirSampler{Int}(rng, 2, m; ordered = true)
        for x in 1:5 fit!(s1, x, 1.0) end
        for x in 6:10 fit!(s2, x, 1.0) end
        @test_throws "Merging ordered reservoirs is not possible" merge!(s1, s2)
    end
end

@testset "merge/merge! below the reservoir size" begin
    rng = StableRNG(56)
    reps = 10^5
    # weights equal to the elements, so that misplaced weights are detected
    fitx!(s, m, x) = m isa AlgWRSWRSKIP ? fit!(s, x, Float64(x)) : fit!(s, x)
    for m in (AlgRSWRSKIP(), AlgWRSWRSKIP()), f in (merge, merge!), N in (4, 6, 10)
        counts = zeros(Int, N)
        for _ in 1:reps
            s1, s2 = ReservoirSampler{Int}(rng, 6, m), ReservoirSampler{Int}(rng, 6, m)
            for x in 1:2 fitx!(s1, m, x) end
            for x in 3:4 fitx!(s2, m, x) end
            s = f(s1, s2)
            for x in 5:N fitx!(s, m, x) end
            for x in value(s) counts[x] += 1 end
        end
        ps = m isa AlgWRSWRSKIP ? collect(1:N) ./ sum(1:N) : fill(1/N, N)
        @test pvalue(ChisqTest(counts, ps)) > 0.001
    end
    for m in (AlgRSWRSKIP(), AlgWRSWRSKIP()), f in (merge, merge!)
        s = f(ReservoirSampler{Int}(rng, 3, m), ReservoirSampler{Int}(rng, 3, m))
        @test isempty(value(s))
        fitx!(s, m, 1)
        @test value(s) == [1, 1, 1]
        s1, s2 = ReservoirSampler{Int}(rng, 3, m), ReservoirSampler{Int}(rng, 3, m)
        for x in 1:5 fitx!(s1, m, x) end
        s = empty!(f(s1, s2))
        fitx!(s, m, 1)
        @test value(s) == [1, 1, 1]
    end
end
