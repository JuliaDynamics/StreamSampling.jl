
using StreamSampling
using Random, StatsBase, Distributions
using ChunkSplitters
using PyCall, BenchmarkTools
using CairoMakie

################
## sequential ##
################

using AliasTables
using Random, StatsBase, Distributions

function weighted_reservoir_sample(rng, a, ws, n)
    return shuffle!(rng, weighted_reservoir_sample_seq(rng, a, ws, n)[1])
end

function weighted_reservoir_sample_seq(rng, a, ws, n)
    @assert length(a) >= n
    view_w_f_n = @view(ws[1:n])
    reservoir = rand(rng, AliasTable(view_w_f_n), n)
    w_sum, w_sum_chunk = sum(view_w_f_n), 0.0
    w_skip_chunk = skip(rng, w_sum, n)
    @inbounds for i in n+1:length(a)
        w_el = ws[i]
        w_sum_chunk += w_el
        if w_sum_chunk > w_skip_chunk
            w_sum_new = w_sum + w_sum_chunk
            p = w_el/w_sum_new
            k = choose(rng, n, p)
            if k == 1
                reservoir[rand(rng, 1:n)] = a[i]
            else
                for j in 1:k
        	    reservoir[rand(rng, j:n)], reservoir[j] = reservoir[j], a[i]
                end
            end
            w_skip_chunk = skip(rng, w_sum_new, n)
            w_sum, w_sum_chunk = w_sum_new, 0.0
        end
    end
    return reservoir, w_sum + w_sum_chunk
end

function skip(rng, w_sum, n)
    z = exp(-randexp(rng)/n)
    return w_sum*((1-z)/z)
end

@inline function choose(rng, n, p)
    z = exp(n*log1p(-p))
    t = rand(rng, Uniform(z, 1.0))
    s = n*p
    q = 1-p
    x = z + z*s/q
    x > t && return 1
    s *= (n-1)*p
    q *= 1-p
    x += (s*z/q)/2
    x > t && return 2
    s *= (n-2)*p
    q *= 1-p
    x += (s*z/q)/6
    x > t && return 3
    s *= (n-3)*p
    q *= 1-p
    x += (s*z/q)/24
    x > t && return 4
    s *= (n-4)*p
    q *= 1-p
    x += (s*z/q)/120
    x > t && return 5
    return quantile(Binomial(n, p), t)
end

#####################
## parallel 1 pass ##
#####################

function weighted_reservoir_sample_parallel_1_pass(rngs, a, ws, n)
    nt = Threads.nthreads()
    ss = Vector{Vector{eltype(a)}}(undef, nt)
    w_sums = Vector{Float64}(undef, nt)
    chunks_inds = index_chunks(a; n=nt)
    Threads.@threads for (i, inds) in enumerate(chunks_inds)
        s = weighted_reservoir_sample_seq(rngs[i], @view(a[inds]), @view(ws[inds]), n)
        ss[i], w_sums[i] = s
    end
    W = sum(w_sums)
    w_sums /= W
    ns = rand(rngs[1], Multinomial(n, w_sums))
    Threads.@threads for i in 1:nt
        ss[i] = sample(rngs[i], ss[i], ns[i]; replace = false)
    end
    return shuffle!(rngs[1], reduce(vcat, ss))
end

#####################
## parallel 2 pass ##
#####################

function weighted_reservoir_sample_parallel_2_pass(rngs, a, ws, n)
    nt = Threads.nthreads()
    chunks_inds = index_chunks(a; n=nt)
    w_sums = Vector{Float64}(undef, nt)
    Threads.@threads for (i, inds) in enumerate(chunks_inds)
        w_sums[i] = sum(@view(ws[inds]))
    end
    ss = Vector{Vector{eltype(a)}}(undef, nt)
    W = sum(w_sums)
    w_sums /= W
    ns = rand(rngs[1], Multinomial(n, w_sums))
    Threads.@threads for (i, inds) in enumerate(chunks_inds)
        s = weighted_reservoir_sample_seq(rngs[i], @view(a[inds]), @view(ws[inds]), ns[i])
        ss[i] = s[1]
    end
    return shuffle!(rngs[1], reduce(vcat, ss))
end

function sample_parallel_2_pass(rngs, a, ws, n)
    nt = Threads.nthreads()
    chunks_inds = index_chunks(a; n=nt)
    w_sums = Vector{Float64}(undef, nt)
    Threads.@threads for (i, inds) in enumerate(chunks_inds)
        w_sums[i] = sum(@view(ws[inds]))
    end
    ss = Vector{Vector{eltype(a)}}(undef, nt)
    W = sum(w_sums)
    w_sums /= W
    ns = rand(rngs[1], Multinomial(n, w_sums))
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
rngs = Tuple(Xoshiro(rand(rng, 1:10000)) for _ in 1:Threads.nthreads());

a = collect(1:10^8);
wsa = Float64.(a);

times_other_parallel = Float64[]
for i in 0:7
    b = @benchmark sample_parallel_2_pass($rngs, $a, $wsa, 10^$i) seconds=20
    push!(times_other_parallel, median(b.times)/10^6)
    println("other $(10^i): $(median(b.times)/10^6) ms")
end

times_other = Float64[]
for i in 0:7
    b = @benchmark sample($rng, $a, Weights($wsa), 10^$i; replace = true) seconds=20
    push!(times_other, median(b.times)/10^6)
    println("other $(10^i): $(median(b.times)/10^6) ms")
end

## single thread
times_single_thread = Float64[]
for i in 0:7
    b = @benchmark weighted_reservoir_sample($rng, $a, $wsa, 10^$i) seconds=20
    push!(times_single_thread, median(b.times)/10^6)
    println("sequential $(10^i): $(median(b.times)/10^6) ms")
end

# multi thread 1 pass - 6 threads
times_multi_thread = Float64[]
for i in 0:7
    b = @benchmark weighted_reservoir_sample_parallel_1_pass($rngs, $a, $wsa, 10^$i) seconds=20
    push!(times_multi_thread, median(b.times)/10^6)
    println("parallel $(10^i): $(median(b.times)/10^6) ms")
end

# multi thread 2 pass - 6 threads
times_multi_thread_2 = Float64[]
for i in 0:7
    b = @benchmark weighted_reservoir_sample_parallel_2_pass($rngs, $a, $wsa, 10^$i) seconds=20
    push!(times_multi_thread_2, median(b.times)/10^6)
    println("parallel $(10^i): $(median(b.times)/10^6) ms")
end

py"""
import numpy as np
import timeit

a = np.arange(1, 10**8+1, dtype=np.int64);
wsa = np.arange(1, 10**8+1, dtype=np.float64)
p = wsa/np.sum(wsa);

def sample_times_numpy():
    times_numpy = []
    for i in range(8):
        ts = []
        for j in range(11):
            t = timeit.timeit("np.random.choice(a, size=10**i, replace=True, p=p)", 
                              setup=f"from __main__ import a, p; import numpy as np; i={i}", 
                              number=1)
            ts.append(t)
        tv = (sorted(ts)[5]*10**3)
        times_numpy.append(tv)
        print(tv)
    return times_numpy
"""
times_numpy = py"sample_times_numpy()"
               
f = Figure(backgroundcolor = RGBf(0.98, 0.98, 0.98), size = (700, 600), dpi=1200);

ax1 = Axis(f[1, 1], yscale=log10, xscale=log10, 
	   yminorticksvisible = true, yminorgridvisible = true, 
	   yminorticks = IntervalsBetween(10), xticklabelsize=15, yticklabelsize=15, titlesize=16,
       xlabelsize=17, ylabelsize=17,)

scatterlines!(ax1, [10^i/10^8 for i in 2:7], times_numpy[3:end]./10^3, label = "numpy.choice sequential", marker = :circle, markersize = 12, linestyle = :dot)
scatterlines!(ax1, [10^i/10^8 for i in 2:7], times_other[3:end]./10^3, label = "StatsBase.sample sequential", marker = :rect, markersize = 12, linestyle = :dot)
scatterlines!(ax1, [10^i/10^8 for i in 2:7], times_other_parallel[3:end]./10^3, label = "StatsBase.sample parallel (2 passes)", marker = :diamond, markersize = 12, linestyle = :dot)
scatterlines!(ax1, [10^i/10^8 for i in 2:7], times_single_thread[3:end]./10^3, label = "WRSWR-SKIP sequential", marker = :hexagon, markersize = 12, linestyle = :dot)
scatterlines!(ax1, [10^i/10^8 for i in 2:7], times_multi_thread[3:end]./10^3, label = "WRSWR-SKIP parallel (1 pass)", marker = :cross, markersize = 12, linestyle = :dot)
scatterlines!(ax1, [10^i/10^8 for i in 2:7], times_multi_thread_2[3:end]./10^3, label = "WRSWR-SKIP parallel (2 passes)", marker = :xcross, markersize = 12, linestyle = :dot)
Legend(f[2,1], ax1, labelsize=12, framevisible = false, orientation = :horizontal, nbanks = 3)

ax1.xtickformat = x -> string.(round.(x.*100, digits=10)) .* "%"
ax1.title = "Comparison between weighted sampling algorithms in a non-streaming context"
ax1.xticks = [10^(i)/10^8 for i in 2:7]
ax1.yticks = [10^float(i) for i in -1:1]

ax1.xlabel = "sample ratio"
ax1.ylabel = "time (s)"

f
save("comparison_WRSWR_SKIP_alg_no_stream.png", f)
