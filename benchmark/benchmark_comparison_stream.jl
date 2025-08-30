
using StreamSampling, StatsBase
using Random, Printf, BenchmarkTools

function samplesum(rng, stream, n, replace)
    pop = collect(stream)
    return sum(sample(rng, pop, n; replace))
end
function samplesum(rng, stream, wf, n, replace)
    pop = collect(stream)
    weights = wf.(pop)
    return sum(sample(rng, pop, Weights(weights), n; replace))
end

function rsvsamplesum(rng, stream, wf, n, alg)
    rs = ReservoirSampler{Int}(rng, n, alg; mutable=false)
    if alg in (AlgL(), AlgRSWRSKIP())
        for i in stream
            rs = fit!(rs, i)
        end
    else
        for i in stream
            rs = fit!(rs, i, wf(i))
        end
    end
    return sum(value(rs))
end

function strsamplesum(rng, stream, wf, n, alg, W=nothing)
    W == nothing && (W = sum(wf(x) for x in stream))
    st = if alg in (AlgD(), AlgORDSWR())
        StreamSampler{Int}(rng, stream, n, W, alg)
    else
        StreamSampler{Int}(rng, stream, w, n, W, alg)
    end
    return sum(st)
end

rng = Xoshiro(42);
stream = Iterators.filter(x -> x != 0, 1:10^8);
W = 10^8
w(el) = 1.0;
w2(el) = 1;

const algrsv = (AlgL(), AlgRSWRSKIP(), AlgAExpJ(), AlgWRSWRSKIP())
const algstr = (AlgD(), AlgORDSWR(), nothing, AlgORDWSWR())
sizes = (10^4, 10^5, 10^6, 10^7)

m_times = Matrix{Vector{Float64}}(undef, (4, 4));
for i in eachindex(m_times) m_times[i] = Float64[] end
m_mems = Matrix{Vector{Float64}}(undef, (4, 4));
for i in eachindex(m_mems) m_mems[i] = Float64[] end

for size in sizes
    i = 0
    for weighted in (false, true)
        for replace in (false, true)
            if weighted
                b1 = @benchmark samplesum($rng, $stream, $w, $size, $replace) seconds=20
            else
                b1 = @benchmark samplesum($rng, $stream, $size, $replace) seconds=20
            end
            i += 1
            push!(m_times[1, i], median(b1.times) * 1e-6)
            push!(m_mems[1, i], b1.memory * 1e-6)
        end
    end
end
for n in sizes
    i = 0
    for alg in algrsv
        b2 = @benchmark rsvsamplesum($rng, $stream, $w, $n, $alg) seconds=20
        i += 1
        push!(m_times[2, i], median(b2.times) * 1e-6)
        push!(m_mems[2, i], b2.memory * 1e-6)
    end
end
for n in sizes
    i = 0
    for alg in algstr
        i += 1
        alg == nothing && continue
        if alg in (AlgD(), AlgORDSWR())
            b3 = @benchmark strsamplesum($rng, $stream, $w2, $n, $alg) seconds=20
            b4 = @benchmark strsamplesum($rng, $stream, $w2, $n, $alg, $W) seconds=20
        else
            b3 = @benchmark strsamplesum($rng, $stream, $w, $n, $alg) seconds=20
            b4 = @benchmark strsamplesum($rng, $stream, $w, $n, $alg, $(Float64(W))) seconds=20
        end
        push!(m_times[3, i], median(b3.times) * 1e-6)
        push!(m_mems[3, i], b3.memory * 1e-6)
        push!(m_times[4, i], median(b4.times) * 1e-6)
        push!(m_mems[4, i], b4.memory * 1e-6)
    end
end

using CairoMakie

f = Figure(fontsize = 9,);
axs = [Axis(f[i, j], yscale = log10, xscale = log10, xgridstyle = :dot,
          ygridstyle = :dot) for i in 1:4 for j in 1:2];

labels = ("population", "reservoir", "stream", "stream - one pass" )

markers = (:circle, :rect, :utriangle, :xcross)
a, b = 0, 0

for j in 1:8
    m = j in (3, 4, 7, 8) ? m_mems : m_times
    m == m_mems ? (a += 1) : (b += 1)
    s = m == m_mems ? a : b
    for i in 1:4
        length(m[i, s]) != 4 && continue
        t = deepcopy(m[i, s])
        scatterlines!(axs[j], [0.01, 0.1, 1, 10], t; label = labels[i], marker = markers[i], linestyle=(:dash, :dense))
    end
    if j in (1,3,5,7)
        axs[j].ylabel = m == m_mems ? "memory (Mb)" : "time (ms)"
    end
    axs[j].xtickformat = x -> string.(x) .* "%"
    j in (7, 8) && (axs[j].xlabel = "sample size")
    pr = j in (1, 2) ? "un" : ""
    t = j in (1, 5) ? "out" : "" 
    j in (1, 2, 5, 6) && (axs[j].title = pr * "weighted with" * t * " replacement")
    axs[j].titlegap = 8.0
    j in (1, 2, 5, 6) && hidexdecorations!(axs[j], grid = false)
end

for i in 1:8
    axs[i].yticks = LogTicks(WilkinsonTicks(4, k_min=4, k_max=6))
end

linkyaxes!((axs[i] for i in [1,2,5,6])...)
linkyaxes!((axs[i] for i in [3,4,7,8])...)

for i in [2,4,6,8]
    axs[i].yticklabelsvisible = false
end
for i in [3,4]
    axs[i].xticklabelsvisible = false
end


f[5, 1] = Legend(f, axs[1], framevisible = false, orientation = :horizontal, 
        halign = :center, padding=(248,0,0,0))

Label(f[0, :], "Performance of Sampling Algorithms on Iterators", fontsize = 13,
    font=:bold)

f

save("comparison_stream_algs.pdf", f)

