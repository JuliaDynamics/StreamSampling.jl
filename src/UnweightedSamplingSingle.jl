
mutable struct ResSampleSingleAlgL{T,R} <: AbstractReservoirSample
    state::Float64
    skip_k::Int
    rng::R
    value::T
    ResSampleSingleAlgL{T,R}(state, skip_k, rng) where {T,R} = new{T,R}(state, skip_k, rng)
end

mutable struct ResSampleSingleAlgR{T,R} <: AbstractReservoirSample
    state::Int
    rng::R
    value::T
    ResSampleSingleAlgR{T,R}(state, rng) where {T,R} = new{T,R}(state, rng)
end

function value(s::ResSampleSingleAlgL)
    s.state === 1.0 && return nothing
    return s.value
end
function value(s::ResSampleSingleAlgR)
    s.state === 0 && return nothing
    return s.value
end

function ReservoirSample(T; method = :alg_L)
    return ReservoirSample(Random.default_rng(), T; method = method)
end
function ReservoirSample(rng::AbstractRNG, T; method = :alg_L)
    if method === :alg_L
        return ResSampleSingleAlgL{T, typeof(rng)}(1.0, 0, rng)
    else
        return ResSampleSingleAlgR{T, typeof(rng)}(0, rng)
    end
end

function update!(s::ResSampleSingleAlgR, el)
    s.state += 1
    if rand(s.rng) <= 1/s.state
        s.value = el
    end
    return s
end

function update!(s::ResSampleSingleAlgL, el)
    if s.skip_k > 0
        s.skip_k -= 1
    else
        s.value = el
        s.state *= rand(s.rng)
        s.skip_k = -ceil(Int, randexp(s.rng)/log(1-s.state))
    end
    return s
end

function itsample(iter; kwargs...)
    return itsample(Random.default_rng(), iter)
end

function itsample(rng::AbstractRNG, iter; kwargs...)
    if Base.IteratorSize(iter) isa Base.SizeUnknown
        return reservoir_sample(rng, iter; kwargs...)
    else 
        return sortedindices_sample(rng, iter; kwargs...)
    end
end

function reservoir_sample(rng, iter; method = :alg_L)
    s = ReservoirSample(rng, Base.@default_eltype(iter); method = method)
    for x in iter
        @inline update!(s, x)
    end
    return value(s)
end
