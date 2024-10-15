
using StreamSampling
using StatsBase
using OnlineStatsBase
using HybridStructs
using DataStructures
using Random

struct AlgAExpJWR end

struct SampleMultiAlgAExpJWR{B, R, T} <: AbstractReservoirSample
    n::Int
    seen_k::Int
    w_sum::Float64
    rng::R
    value::B
    value_prev::Vector{T}
    weights::Vector{Float64}
end

function StreamSampling.ReservoirSample{T}(rng::AbstractRNG, n::Integer, ::AlgAExpJWR,
        ::StreamSampling.ImmutSample, ::StreamSampling.Unord) where T
    value = BinaryHeap(Base.By(first, DataStructures.FasterForward()), Tuple{Float64,T}[])
    sizehint!(value, n)
    v = Vector{T}(undef, n)
    w = Vector{Float64}(undef, n)
    return SampleMultiAlgAExpJWR(n, 0, 0.0, rng, value, v, w)
end

@inline function OnlineStatsBase._fit!(s::SampleMultiAlgAExpJWR, el, w)
    n = s.n
    s = @inline update_state!(s, w)
    if s.seen_k <= n
        @inbounds s.value_prev[s.seen_k] = el
        @inbounds s.weights[s.seen_k] = w
        if s.seen_k === n
            for x in sample(s.rng, s.value_prev, Weights(s.weights, s.w_sum), n)
                push!(s.value, (skip_single(s.rng, s.w_sum), x))
            end
            empty!(s.value_prev)
            empty!(s.weights)
        end
    else
        while first(s.value)[1] <= s.w_sum
            pop!(s.value)
            push!(s.value, (skip_single(s.rng, s.w_sum), el))
        end
    end
    return s
end

skip_single(rng, n) = n/rand(rng)

function update_state!(s::SampleMultiAlgAExpJWR, w)
    @update s.seen_k += 1
    @update s.w_sum += w
    return s
end

function OnlineStatsBase.value(s::SampleMultiAlgAExpJWR)
    return shuffle!(s.rng, last.(s.value.valtree))
end

a = Iterators.filter(x -> x != 1, 1:10^8)
wv_const(x) = 1.0
wv_incr(x) = Float64(x)
wv_decr(x) = 1/x
wvs = ((:wv_decr, wv_decr), 
       (:wv_const, wv_const),
       (:wv_incr, wv_incr))

benchs = []
for (wvn, wv) in wvs
    for m in (AlgAExpJWR(), AlgWRSWRSKIP())
        bs = []
        for sz in [10^i for i in 0:7]
            b = @benchmark itsample($a, $wv, $sz, $m) seconds=20
            push!(bs, median(b.times))
            println(median(b.times))
        end
        push!(benchs, (wvn, m, bs))
        println(benchs)
    end
end

using CairoMakie

f = Figure(backgroundcolor = RGBf(0.98, 0.98, 0.98), size = (1100, 700));

f.title = "Comparison between AExpJ-WR and WRSWR-SKIP Algorithms"

ax1 = Axis(f[1, 1], yscale=log10, xscale=log10, 
       yminorticksvisible = true, yminorgridvisible = true, 
       yminorticks = IntervalsBetween(10))
ax2 = Axis(f[1, 2], yscale=log10, xscale=log10, 
       yminorticksvisible = true, yminorgridvisible = true, 
       yminorticks = IntervalsBetween(10))
ax3 = Axis(f[1, 3], yscale=log10, xscale=log10, 
       yminorticksvisible = true, yminorgridvisible = true, 
       yminorticks = IntervalsBetween(10))

for x in benchs
    label = x[1] == :wv_const ? (x[2] == AlgAExpJWR() ? "ExpJ-WR" : "WRSWR-SKIP") : ""
    ax = x[1] == :wv_decr ? ax1 : (x[1] == :wv_const ? ax2 : ax3)
    marker = x[2] == AlgAExpJWR() ? :circle : (:xcross)
    scatterlines!(ax, [10^i/10^8 for i in 3:7], x[3][4:end] ./ 10^6, marker = marker, 
                  label = label, markersize = 12, linestyle = :dot)
end

Legend(f[2,:], ax2, labelsize=10, framevisible = false)

for ax in [ax1, ax2, ax3]
    ax.xtickformat = x -> string.(round.(x.*100, digits=10)) .* "%"
    #ax.ytickformat = y -> y .* "^"
    ax.title = ax == ax1 ? "decreasing weights" : (ax == ax2 ? "constant weights" : "increasing weights")
    ax.xticks = [10^(i)/10^8 for i in 3:7]
    ax.yticks = [10^i for i in 2:4]
    ax.xlabel = "sample ratio"
    ax == ax1 && (ax.ylabel = "time (ms)")
end

save("comparison_WRSWR_SKIP_alg_stream.png", f)
f