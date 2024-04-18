
mutable struct SampleMultiAlgARes{BH,R} <: AbstractWeightedWorReservoirSampleMulti
    seen_k::Int
    n::Int
    rng::R
    value::BH
end

mutable struct SampleMultiAlgAExpJ{BH,R} <: AbstractWeightedWorReservoirSampleMulti
    state::Float64
    min_priority::Float64
    seen_k::Int
    n::Int
    rng::R
    value::BH
end

mutable struct SampleMultiAlgWRSWRSKIP{T,R} <: AbstractWeightedWrReservoirSampleMulti
    state::Float64
    skip_w::Float64
    seen_k::Int
    rng::R
    weights::Vector{Float64}
    value::Vector{T}
end

mutable struct SampleMultiOrdAlgWRSWRSKIP{T,R} <: AbstractWeightedWrReservoirSampleMulti
    state::Float64
    skip_w::Float64
    seen_k::Int
    rng::R
    weights::Vector{Float64}
    value::Vector{T}
    ord::Vector{Int}
end

function ReservoirSample(rng::AbstractRNG, T, n::Integer, method::AlgAExpJ; ordered = false)
    value = BinaryHeap(Base.By(last), Pair{T, Float64}[])
    sizehint!(value, n)
    if ordered
        error("Not implemented yet")
    else
        return SampleMultiAlgAExpJ(0.0, 0.0, 0, n, rng, value)
    end
end
function ReservoirSample(rng::AbstractRNG, T, n::Integer, method::AlgARes; ordered = false)
    value = BinaryHeap(Base.By(last), Pair{T, Float64}[])
    sizehint!(value, n)
    if ordered
        error("Not implemented yet")
    else
        return SampleMultiAlgARes(0, n, rng, value)
    end
end
function ReservoirSample(rng::AbstractRNG, T, n::Integer, method::AlgWRSWRSKIP; ordered = false)
    value = Vector{T}(undef, n)
    weights = Vector{Float64}(undef, n)
    if ordered
        ord = collect(1:n)
        return SampleMultiOrdAlgWRSWRSKIP(0.0, 0.0, 0, rng, weights, value, ord)
    else
        return SampleMultiAlgWRSWRSKIP(0.0, 0.0, 0, rng, weights, value)
    end
end

@inline function update!(s::SampleMultiAlgARes, el, w)
    n = s.n
    s.seen_k += 1
    priority = -randexp(s.rng)/w
    if s.seen_k <= n
        push!(s.value, el => priority)
    else
        min_priority = last(first(s.value))
        if priority > min_priority
            pop!(s.value)
            push!(s.value, el => priority)
        end
    end
    return s
end
@inline function update!(s::SampleMultiAlgAExpJ, el, w)
    n = s.n
    s.seen_k += 1
    s.state -= w
    if s.seen_k <= n
        priority = exp(-randexp(s.rng)/w)
        push!(s.value, el => priority)
        s.seen_k == n && @inline recompute_skip!(s)
    elseif s.state <= 0.0
        priority = @inline compute_skip_priority(s, w)
        pop!(s.value)
        push!(s.value, el => priority)
        @inline recompute_skip!(s)
    end
    return s
end
@inline function update!(s::Union{SampleMultiAlgWRSWRSKIP, SampleMultiOrdAlgWRSWRSKIP}, el, w)
    n = length(s.value)
    s.seen_k += 1
    s.state += w
    if s.seen_k <= n
        @inbounds s.value[s.seen_k] = el
        @inbounds s.weights[s.seen_k] = w
        if s.seen_k == n
            s.value = sample(s.rng, s.value, weights(s.weights), n; ordered = is_ordered(s))
            @inline recompute_skip!(s, n)
            empty!(s.weights)
        end
    elseif s.skip_w <= s.state
        p = w/s.state
        z = (1-p)^(n-3)
        q = rand(s.rng, Uniform(z*(1-p)*(1-p)*(1-p),1.0))
        k = choose(n, p, q, z)
        @inbounds begin
            if k == 1
                r = rand(s.rng, 1:n)
                s.value[r] = el
                update_order_single!(s, r)
            else
                for j in 1:k
                    r = rand(s.rng, j:n)
                    s.value[r] = el
                    s.value[r], s.value[j] = s.value[j], s.value[r]
                    update_order_multi!(s, r, j)
                end
            end 
        end
        @inline recompute_skip!(s, n)
    end
    return s
end

function compute_skip_priority(s, w)
    t = exp(log(s.min_priority)*w)
    return exp(log(rand(s.rng, Uniform(t,1)))/w)
end

function recompute_skip!(s::SampleMultiAlgAExpJ)
    s.min_priority = last(first(s.value))
    s.state = -randexp(s.rng)/log(s.min_priority)
end
function recompute_skip!(s::Union{SampleMultiAlgWRSWRSKIP, SampleMultiOrdAlgWRSWRSKIP}, n)
    q = rand(s.rng)^(1/n)
    s.skip_w = s.state/q
end

update_order_single!(s::SampleMultiAlgWRSWRSKIP, r) = nothing
function update_order_single!(s::SampleMultiOrdAlgWRSWRSKIP, r)
    s.ord[r] = n_seen(s)
end

update_order_multi!(s::SampleMultiAlgWRSWRSKIP, r, j) = nothing
function update_order_multi!(s::SampleMultiOrdAlgWRSWRSKIP, r, j)
    s.ord[r], s.ord[j] = s.ord[j], n_seen(s)
end

is_ordered(s::SampleMultiOrdAlgWRSWRSKIP) = true
is_ordered(s::SampleMultiAlgWRSWRSKIP) = false

function value(s::AbstractWeightedWorReservoirSampleMulti)
    if n_seen(s) < s.n
        return first.(s.value.valtree)[1:n_seen(s)]
    else
        return first.(s.value.valtree)
    end
end
function value(s::AbstractWeightedWrReservoirSampleMulti)
    if n_seen(s) < length(s.value)
        return sample(s.rng, s.value[1:n_seen(s)], weights(s.weights[1:n_seen(s)]), length(s.value))
    else
        return s.value
    end
end

function ordered_value(s::SampleMultiOrdAlgWRSWRSKIP)
    if n_seen(s) < length(s.value)
        return sample(s.rng, s.value[1:n_seen(s)], weights(s.weights[1:n_seen(s)]), length(s.value); ordered=true)
    else
        return s.value[sortperm(s.ord)]
    end
end

n_seen(s::AbstractReservoirSample) = s.seen_k

function itsample(iter, wv::Function, n::Int, 
        method::ReservoirAlgorithm=algAExpJ; ordered = false)
    return itsample(Random.default_rng(), iter, wv, n, method; ordered = ordered)
end

function itsample(rng::AbstractRNG, iter, wv::Function, n::Int, 
        method::ReservoirAlgorithm=algAExpJ; ordered = false)
    return reservoir_sample(rng, iter, wv, n, method; ordered = ordered)
end

function reservoir_sample(rng, iter, wv::Function, n::Int, 
        method::ReservoirAlgorithm=algAExpJ; ordered = false)
    iter_type = calculate_eltype(iter)
    s = ReservoirSample(rng, iter_type, n, method; ordered = ordered)
    return update_all!(s, iter, wv, ordered)
end

function update_all!(s, iter, wv, ordered)
    for x in iter
        update!(s, x, wv(x))
    end
    return ordered ? ordered_value(s) : shuffle!(s.rng, value(s))
end