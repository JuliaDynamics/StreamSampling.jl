
using StreamSampling
using Random, StatsBase, Distributions
using ChunkSplitters
using BenchmarkTools

################
## sequential ##
################

function weighted_reservoir_sample(rng, a, ws, n)
    return shuffle!(rng, weighted_reservoir_sample_seq(rng, a, ws, n)[1])
end

function weighted_reservoir_sample_seq(rng, a, ws, n)
    m = min(length(a), n)
    view_w_f_n = @view(ws[1:m])
    w_sum = sum(view_w_f_n)
    reservoir = sample(rng, @view(a[1:m]), Weights(view_w_f_n, w_sum), n)
    length(a) <= n && return reservoir, w_sum
    w_skip = skip(rng, w_sum, n)
    @inbounds for i in n+1:length(a)
        w_el = ws[i]
        w_sum += w_el
        if w_sum > w_skip
            p = w_el/w_sum
            q = 1-p
            z = q^(n-3)
            t = rand(rng, Uniform(z*q*q*q,1.0))
            k = choose(n, p, q, t, z)
            for j in 1:k
                r = rand(rng, j:n)
                @inbounds reservoir[r], reservoir[j] = reservoir[j], a[i]
            end 
            w_skip = skip(rng, w_sum, n)
        end
    end
    return reservoir, w_sum
end

function skip(rng, w_sum::AbstractFloat, n)
    k = rand(rng)^(1/n)
    return w_sum/k
end

function choose(n, p, q, t, z)
    x = z*q*q*(q + n*p)
    x > t && return 1
    x += n*p*(n-1)*p*z*q/2
    x > t && return 2
    x += n*p*(n-1)*p*(n-2)*p*z/6
    x > t && return 3
    return quantile(Binomial(n, p), t)
end

#####################
## parallel 1 pass ##
#####################

function weighted_reservoir_sample_parallel_1_pass(rngs, a, ws, n)
    nt = Threads.nthreads()
    ss = Vector{Vector{Int}}(undef, nt)
    w_sums = Vector{Float64}(undef, nt)
    chunks_inds = chunks(a; n=nt)
    Threads.@threads for (i, inds) in enumerate(chunks_inds)
        s = weighted_reservoir_sample_seq(rngs[i], @view(a[inds]), @view(ws[inds]), n)
        ss[i], w_sums[i] = s
    s_all = Vector{eltype(a)}(undef, n*nt)
    ws_all = Vector{Float64}(undef, n*nt)
    q = 1
    for c in 1:nt
        s, w_sum = ss[c], w_sums[c]
        @inbounds @simd for e in s
            s_all[q], ws_all[q] = e, w_sum
            q += 1
        end
    end
    return sample(rng, s_all, Weights(ws_all, n*sum(w_sums)), n)
end

#####################
## parallel 2 pass ##
#####################

function weighted_reservoir_sample_parallel_2_pass(rngs, a, ws, n)
    nt = Threads.nthreads()
    chunks_inds = chunks(a; n=nt)
    w_sums = Vector{Float64}(undef, nt)
    Threads.@threads for (i, inds) in enumerate(chunks_inds)
        w_sums[i] = sum(@view(ws[inds]))
    end
    ss = Vector{Vector{Int}}(undef, nt)
    ps = w_sums ./ sum(w_sums)
    ns = rand(rngs[1], Multinomial(n, ps))
    Threads.@threads for (i, inds) in enumerate(chunks_inds)
        s = weighted_reservoir_sample_seq(rngs[i], @view(a[inds]), @view(ws[inds]), ns[i])
        ss[i] = s[1]
    end
    return shuffle!(rngs[1], reduce(vcat, ss))
end


function sample_parallel(rngs, a, ws, n)
    nt = Threads.nthreads()
    chunks_inds = chunks(a; n=nt)
    w_sums = Vector{Float64}(undef, nt)
    Threads.@threads for (i, inds) in enumerate(chunks_inds)
        w_sums[i] = sum(@view(ws[inds]))
    end
    ss = Vector{Vector{Int}}(undef, nt)
    ps = w_sums ./ sum(w_sums)
    ns = rand(rngs[1], Multinomial(n, ps))
    Threads.@threads for (i, inds) in enumerate(chunks_inds)
        s = sample(rngs[i], @view(a[inds]), Weights(@view(ws[inds])), ns[i]; replace = true)
        ss[i] = s
    end
    return shuffle!(rngs[1], reduce(vcat, ss))
end

################
## benchmarks ##
################

rng = Xoshiro(42);
rngs = Tuple(Xoshiro(rand(rng, 1:10000)) for _ in 1:2*Threads.nthreads());

a = Tuple(Iterators.filter(x -> x != 1, 1:10^7) for i in 1:6);
a = Iterators.filter(x -> x != 1, 1:6*10^7)
wsa = rand(rng, 10^8);
wv(x) = convert(Float64, x/1000);
wvs = Tuple(wv for _ in 1:Threads.nthreads());

times_other_parallel = Float64[]
for i in 0:7
    b = @benchmark sample_parallel($rngs, $a, $wsa, 10^$i)
    push!(times_other_parallel, me17.352dian(b.times)/10^9)
    println("other $(10^i): $(median(b.times)/10^9) s")
end

times_other = Float64[]
for i in 0:7
    b = @benchmark sample($rng, $a, Weights($wsa), 10^$i; replace = true)
    push!(times_other, median(b.times)/10^9)
    println("other $(10^i): $(median(b.times)/10^9) s")
end

## single thread
times_single_thread = Float64[]
for i in 0:7
    b = @benchmark weighted_reservoir_sample($rng, $a, $wsa, 10^$i)
    push!(times_single_thread, median(b.times)/10^9)
    println("sequential $(10^i): $(median(b.times)/10^9) s")
end

# multi thread 1 pass - 6 threads
times_multi_thread = Float64[]
for i in 0:7
    b = @benchmark weighted_reservoir_sample_parallel_1_pass($rngs, $a, $wsa, 10^$i)
    push!(times_multi_thread, median(b.times)/10^9)
    println("parallel $(10^i): $(median(b.times)/10^9) s")
end

# multi thread 2 pass - 6 threads
times_multi_thread_2 = Float64[]
for i in 0:7
    b = @benchmark weighted_reservoir_sample_parallel_2_pass($rngs, $a, $wsa, 10^$i)
    push!(times_multi_thread_2, median(b.times)/10^9)
    println("parallel $(10^i): $(median(b.times)/10^9) s")
end

times_numpy = [0.8696490620000077, 0.7254721580002297, 0.7246720650000498, 0.725973069000247, 
               0.7360188430002381, 0.8357699029998003, 1.8281514250002147, 11.761755672000163]
               
using CairoMakie

f = Figure(backgroundcolor = RGBf(0.98, 0.98, 0.98), size = (1100, 700));

ax1 = Axis(f[1, 1], yscale=log10, xscale=log10, 
	   yminorticksvisible = true, yminorgridvisible = true, 
	   yminorticks = IntervalsBetween(10))

scatterlines!(ax1, [10^i/10^8 for i in 2:7], times_numpy[3:end], color = :pink, label = "numpy.choice sequential")
scatterlines!(ax1, [10^i/10^8 for i in 2:7], times_other[3:end], color = :green, label = "StatsBase.sample sequential")
scatterlines!(ax1, [10^i/10^8 for i in 2:7], times_other_parallel[3:end], color = :black, label = "StatsBase.sample parallel")
scatterlines!(ax1, [10^i/10^8 for i in 2:7], times_other[3:end]./Threads.nthreads(), color = :gray, linestyle=:dot, label = "StatsBase.sample parallel (optimal)")
scatterlines!(ax1, [10^i/10^8 for i in 2:7], times_single_thread[3:end], color = :blue, label = "StreamSampling.itsample sequential")
scatterlines!(ax1, [10^i/10^8 for i in 2:7], times_multi_thread[3:end], color = :red, label = "StreamSampling.itsample parallel (1 pass)")
scatterlines!(ax1, [10^i/10^8 for i in 2:7], times_multi_thread_2[3:end], color = :orange, label = "StreamSampling.itsample parallel (2 passes)")
scatterlines!(ax1, [10^i/10^8 for i in 2:7], times_single_thread[3:end]./, color = :gray, linestyle=:dash, label = "StreamSampling.itsample parallel (optimal)")
Legend(f[1,2], ax1, labelsize=10)

ax1.xtickformat = x -> string.(round.(x.*100, digits=10)) .* "%"
ax1.title = "Comparison between weighted sampling reservoir-based algorithms and others in a non-streaming context"
ax1.xticks = [10^(i)/10^8 for i in 2:7]
ax1.yticks = [10^(i)/10^3 for i in 1:4]
ylims!(ax1, low = 0.01, high=15.0)


ax1.xlabel = "sample ratio"
ax1.ylabel = "time (s)"

save("comparison_WRSWRSKIP_alg.png")
f


# Python code with Numpy - To be Executed in a Python Environment

import numpy as np
import timeit

a = np.arange(1, 10**8+1, dtype=np.int64);
wsa = np.arange(1, 10**8+1, dtype=np.float64)
p = wsa/np.sum(wsa);

times_numpy = []
for i in range(8):
    ts = []
    for j in range(3):
    	t = timeit.timeit("np.random.choice(a, size=10**i, replace=True, p=p)", setup=f"from __main__ import a, p; import numpy as np; i={i}", number=1)
    	ts.append(t)
    times_numpy.append(ts[1])
    print(ts[1])




