
using StreamSampling, StatsBase
using Random, Printf, BenchmarkTools
using CairoMakie

rng = Xoshiro(42);
stream = Iterators.filter(x -> x != 10, 1:10^7);
pop = collect(stream);
w(el) = 1.0;
weights = Weights(w.(stream));

algs = (algL, algRSWRSKIP, algAExpJ, algWRSWRSKIP);
algsweighted = (algAExpJ, algWRSWRSKIP);
algsreplace = (algRSWRSKIP, algWRSWRSKIP);
sizes = (10^3, 10^4, 10^5, 10^6)

p = Dict((0, 0) => 1, (0, 1) => 2, (1, 0) => 3, (1, 1) => 4);
m_times = Matrix{Vector{Float64}}(undef, (3, 4));
for i in eachindex(m_times) m_times[i] = Float64[] end
m_mems = Matrix{Vector{Float64}}(undef, (3, 4));
for i in eachindex(m_mems) m_mems[i] = Float64[] end

for m in algs
    for size in sizes
        replace = m in algsreplace
        weighted = m in algsweighted
        if weighted
            b1 = @benchmark itsample($rng, $stream, $w, $size, $m) evals=1
            b2 = @benchmark sample($rng, collect($stream), Weights($w.($stream)), $size; replace = $replace) evals=1
            b3 = @benchmark sample($rng, $pop, $weights, $size; replace = $replace) evals=1
        else
            b1 = @benchmark itsample($rng, $stream, $size, $m) evals=1
            b2 = @benchmark sample($rng, collect($stream), $size; replace = $replace) evals=1
            b3 = @benchmark sample($rng, $pop, $size; replace = $replace) evals=1
        end
        ts = [median(b1.times), median(b2.times), median(b3.times)] .* 1e-6
        ms = [b1.memory, b2.memory, b3.memory] .* 1e-6
        c = p[(weighted, replace)]
        for r in 1:3
            push!(m_times[r, c], ts[r])
            push!(m_mems[r, c], ms[r])
        end
    end
end

f = Figure();
axs = [Axis(f[i, j], yscale = log10) for i in 1:2 for j in 1:2];
for j in 1:4, i in 1:3 
    scatterlines!(axs[j], 1:4, m_times[i, j]) 
end
f

f = Figure();
axs = [Axis(f[i, j], yscale = log10) for i in 1:2 for j in 1:2];
for j in 1:4, i in 1:3 
    scatterlines!(axs[j], 1:4, m_mems[i, j]) 
end
f
