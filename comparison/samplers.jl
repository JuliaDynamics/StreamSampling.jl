
struct ReservoirSampler{T} end

##### WRSWR-SKIP

struct AlgWRSWRSKIP end

mutable struct AlgWRSWRSKIPSampler{T,R}
    const n::Int
    state::Float64
    skip_w::Float64
    seen_k::Int
    const weights::Memory{Float64}
    const value::Vector{T}
    const ord::Memory{Int}
    const rng::R
end

function ReservoirSampler{T}(rng::AbstractRNG, n::Integer, ::AlgWRSWRSKIP) where T
    ord = Memory{Int}(undef, n); ord .= 1:n
    return AlgWRSWRSKIPSampler(n, 0.0, 0.0, 0, Memory{Float64}(undef, n), Vector{T}(undef, n), ord, rng)
end

@inline function add!(s::AlgWRSWRSKIPSampler, el, w)
    w < 0.0 && error(lazy"Passed element $(el) with weight $(w), but weights must be positive.")
    n = s.n
    @inline update_state!(s, w)
    if s.seen_k <= n
        @inbounds s.value[s.seen_k] = el
        @inbounds s.weights[s.seen_k] = s.state
        if s.seen_k == n
            j, curx = 1, 0.0
            newvalues = similar(s.value)
            @inbounds for i in n:-1:1
                curx += (1-exp(-randexp(s.rng)/i))*(1-curx)
                while s.weights[j] < curx * s.state
                    j += 1
                end
                newvalues[i] = s.value[j]
            end
            s.value .= newvalues
            @inline recompute_skip!(s, n)
        end
    elseif s.skip_w <= s.state
        p = w/s.state
        k = @inline choose(s.rng, n, p)
        @inbounds for j in 1:k
            r = @inline rand(s.rng, Random.Sampler(s.rng, j:n, Val(1)))
            pos = s.ord[r]
            s.value[pos] = el
            s.ord[r], s.ord[j] = s.ord[j], pos
        end 
        @inline recompute_skip!(s, n)
    end
    return s
end

function update_state!(s::AlgWRSWRSKIPSampler, w)
    s.seen_k += 1
    s.state += w
    return s
end

function recompute_skip!(s::AlgWRSWRSKIPSampler, n)
    q = exp(randexp(s.rng)/n)
    s.skip_w = s.state*q
    return s
end

macro quantile_fast(k)
    block = Expr(:block)
    firstv = quote
        $(esc(:s)) = $(esc(:n)) * $(esc(:p))
        $(esc(:q)) = 1. - $(esc(:p))
        $(esc(:x)) = 1. + $(esc(:s)) / $(esc(:q))
        $(esc(:x)) > $(esc(:nt)) && return 1
    end
    append!(block.args, firstv.args)
    for i in 2:k
        nextv = quote
            $(esc(:s)) *= ($(esc(:n)) - $i) * $(esc(:p))
            $(esc(:q)) *= 1. - $(esc(:p))
            $(esc(:x)) += $(esc(:s)) / ($(esc(:q)) * $(factorial(i)))
            $(esc(:x)) > $(esc(:nt)) && return $i
        end
        append!(block.args, nextv.args)
    end
    return block
end

@inline function choose(rng, n, p)
    z = exp(n*log1p(-p))
    t = rand(rng, Uniform(z, 1.0))
    nt = t/z
    @quantile_fast(8)
    return quantile(Binomial(n, p), t)
end

function get(s::AlgWRSWRSKIPSampler)
	if s.seen_k < s.n
		return sample(s.rng, s.value[1:s.seen_k], Weights(s.weigths[1:s.seen_k]), s.n)
	else 
		return s.value
	end
end

##### WRSWR

struct AlgWRSWR end

mutable struct AlgWRSWRSampler{T,R}
    const n::Int
    state::Float64
    const value::Vector{T}
    const rng::R
end

function ReservoirSampler{T}(rng::AbstractRNG, n::Integer, ::AlgWRSWR) where T
    return AlgWRSWRSampler(n, 0.0, Vector{T}(undef, n), rng)
end

@inline function add!(s::AlgWRSWRSampler, el, w)
	s.state += w
	@inbounds @simd for i in 1:s.n
		if rand(s.rng) < w / s.state
			s.value[i] = el
		end
	end
end

function get(s::AlgWRSWRSampler)
	return s.value
end

##### WRSWR-BIN

struct AlgWRSWRBIN end

mutable struct AlgWRSWRBINSampler{T,R}
    const n::Int
    state::Float64
    const value::Vector{T}
    const ord::Vector{Int}
    const rng::R
end

function ReservoirSampler{T}(rng::AbstractRNG, n::Integer, ::AlgWRSWRBIN) where T
    return AlgWRSWRBINSampler(n, 0.0, Vector{T}(undef, n), collect(1:n), rng)
end

@inline function add!(s::AlgWRSWRBINSampler, el, w)
    state_prev = s.state
	s.state = state_prev + w
	n, p = s.n, w/s.state
    if state_prev == 0.0
        fill!(s.value, el)
    else
    	k = @inline choose_with_0(s.rng, n, p)
        @inbounds for j in 1:k
            r = @inline rand(s.rng, Random.Sampler(s.rng, j:n, Val(1)))
            s.value[r], s.value[j] = s.value[j], el
        end 
    end
end

@inline function choose_with_0(rng, n, p)
    z = exp(n*log1p(-p))
    t = rand(rng)
    t < z && return 0
    nt = t/z
    @quantile_fast(8)
    return quantile(Binomial(n, p), t)
end

function get(s::AlgWRSWRBINSampler)
	return s.value
end

##### AExpJWR

struct AlgWRAExpJ end

mutable struct AlgWRAExpJSampler{BH,R,T}
	const value::BH
    const samplevalue::Vector{T}
    const sampler::FixedSizeWeightVector
    state::Float64
    totalw::Float64
    min_priority::Float64
    seen_k::Int
    const n::Int
    const rng::R
end

function ReservoirSampler{T}(rng::AbstractRNG, n::Integer, ::AlgWRAExpJ) where T
    value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), Pair{T, Tuple{Float64,Float64}}[])
    sizehint!(value, n)
    return AlgWRAExpJSampler(value, Vector{T}(undef, n), FixedSizeWeightVector(n), 0.0, 0.0, 0.0, 0, n, rng)
end

@inline function add!(s::AlgWRAExpJSampler, el, w)
    w < 0.0 && error(lazy"Passed element $(el) with weight $(w), but weights must be positive.")
    n = s.n
    s.totalw += w
    @inline update_state!(s, w)
    if s.seen_k <= n
        priority = -randexp(s.rng)/w
        push!(s.value, el => (priority,w))

        if s.seen_k == n 
            @inline recompute_skip!(s)
        end
    elseif s.state <= 0.0
        priority = @inline compute_skip_priority(s, w)
        pop!(s.value)
    	push!(s.value, el => (priority,w))
        @inline recompute_skip!(s)
    end
    return s
end

function recompute_skip!(s::AlgWRAExpJSampler)
    s.min_priority = first(last(first(s.value)))
    s.state = -randexp(s.rng)/s.min_priority
    return s
end

function update_state!(s::AlgWRAExpJSampler, w)
    s.seen_k += 1
    s.state -= w
    return s
end

function compute_skip_priority(s, w)
    t = exp(s.min_priority*w)
    return log(rand(s.rng, Uniform(t,1)))/w
end

function get(s::AlgWRAExpJSampler{<:BinaryHeap{Pair{T, Tuple{Float64,Float64}}}}) where T
    kvs = sort(s.value.valtree, by = x -> x[2][1], rev=true)
    W = s.totalw
    sampler = s.sampler
    if !iszero(sampler)
        @inbounds for i in eachindex(sampler)
            sampler[i] = 0.0
        end
    end
    out = s.samplevalue
    out[1] = kvs[1][1]
    sampler[1] = kvs[1][2][2]
    Wnew = W - kvs[1][2][2]
    sampler[2] = Wnew
    m = 2
    @inbounds for j in 2:s.n
        i = rand(s.rng, sampler)
        if i <= j-1
            out[j] = kvs[i][1]
        else
            out[j] = kvs[m][1]
            m += 1
        end
        if j < s.n
            sampler[j] = kvs[j][2][2]
            Wnew -= kvs[j][2][2]
            sampler[j+1] = Wnew
        end
    end
    return out
end
