
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
wvs = (wv_decr, wv_const, wv_incr)

for wv in wvs
    for m in (AlgWRSWRSKIP(), AlgAExpJWR())
        for sz in [10^i for i in 0:7]
            b = @benchmark itsample($a, $wv, $sz, $m) seconds=10
            println(wv, " ", m, " ", sz, " ", median(b.times))
        end
    end
end

