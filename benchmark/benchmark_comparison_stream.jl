using StreamSampling, StatsBase
using Random, Printf, BenchmarkTools
using CairoMakie

rng = Xoshiro(42);
stream = Iterators.filter(x -> x != 1, 1:10^8);
pop = collect(stream);
w(el) = Float64(el);
weights = Weights(w.(stream));

algs = (AlgL(), AlgRSWRSKIP(), AlgAExpJ(), AlgWRSWRSKIP());
algsweighted = (AlgAExpJ(), AlgWRSWRSKIP());
algsreplace = (AlgRSWRSKIP(), AlgWRSWRSKIP());
sizes = (10^4, 10^5, 10^6, 10^7)

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
            b1 = @benchmark itsample($rng, $stream, $w, $size, $m) seconds=20
            b2 = @benchmark sample($rng, collect($stream), Weights($w.($stream)), $size; replace = $replace) seconds=20
            b3 = @benchmark sample($rng, $pop, $weights, $size; replace = $replace) seconds=20
        else
            b1 = @benchmark itsample($rng, $stream, $size, $m) evals=1 seconds=20
            b2 = @benchmark sample($rng, collect($stream), $size; replace = $replace) seconds=20
            b3 = @benchmark sample($rng, $pop, $size; replace = $replace) seconds=20
        end
        ts = [median(b1.times), median(b2.times), median(b3.times)] .* 1e-6
        ms = [b1.memory, b2.memory, b3.memory] .* 1e-6
        c = p[(weighted, replace)]
        for r in 1:3
            push!(m_times[r, c], ts[r])
            push!(m_mems[r, c], ms[r])
        end
        println("c")
    end
end

f = Figure(fontsize = 9,);
axs = [Axis(f[i, j], yscale = log10, xscale = log10) for i in 1:4 for j in 1:2];

labels = (
    "stream-based\n(StreamSampling.itsample)", 
    "collection-based with setup\n(StatsBase.sample)", 
    "collection-based\n(StatsBase.sample)"
)

markers = (:circle, :rect, :utriangle)
a, b = 0, 0

for j in 1:8
    m = j in (3, 4, 7, 8) ? m_mems : m_times
    m == m_mems ? (a += 1) : (b += 1)
    s = m == m_mems ? a : b
    for i in 1:3 
        scatterlines!(axs[j], [0.01, 0.1, 1, 10], m[i, s]; label = labels[i], marker = markers[i])
    end
    axs[j].ylabel = m == m_mems ? "memory (Mb)" : "time (ms)"
    axs[j].xtickformat = x -> string.(x) .* "%"
    j in (3, 4, 7, 8) && (axs[j].xlabel = "sample size")
    pr = j in (1, 2) ? "un" : ""
    t = j in (1, 5) ? "out" : "" 
    j in (1, 2, 5, 6) && (axs[j].title = pr * "weighted with" * t * " replacement")
    axs[j].titlegap = 8.0
    j in (1, 2, 5, 6) && hidexdecorations!(axs[j], grid = false)
end

f[5, 1] = Legend(f, axs[1], framevisible = false, orientation = :horizontal, 
        halign = :center, padding=(248,0,0,0))

Label(f[0, :], "Comparison between stream-based and collection-based algorithms", fontsize = 13,
    font=:bold)

save("comparison_stream_algs.png", f)
f
