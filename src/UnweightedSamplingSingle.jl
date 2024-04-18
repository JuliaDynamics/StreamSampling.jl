
mutable struct SampleSingleAlgL{T,R} <: AbstractReservoirSample
    state::Float64
    skip_k::Int
    rng::R
    value::T
    SampleSingleAlgL{T,R}(state, skip_k, rng) where {T,R} = new{T,R}(state, skip_k, rng)
end

mutable struct SampleSingleAlgR{T,R} <: AbstractReservoirSample
    state::Int
    rng::R
    value::T
    SampleSingleAlgR{T,R}(state, rng) where {T,R} = new{T,R}(state, rng)
end

function value(s::SampleSingleAlgL)
    s.state === 1.0 && return nothing
    return s.value
end
function value(s::SampleSingleAlgR)
    s.state === 0 && return nothing
    return s.value
end

function ReservoirSample(T, method::ReservoirAlgorithm = algL)
    return ReservoirSample(Random.default_rng(), T, method)
end
function ReservoirSample(rng::AbstractRNG, T, method::AlgL = algL)
    return SampleSingleAlgL{T, typeof(rng)}(1.0, 0, rng)
end
function ReservoirSample(rng::AbstractRNG, T, method::AlgR)
    return SampleSingleAlgR{T, typeof(rng)}(0, rng)
end

@inline function update!(s::SampleSingleAlgR, el)
    s.state += 1
    if rand(s.rng) <= 1/s.state
        s.value = el
    end
    return s
end
@inline function update!(s::SampleSingleAlgL, el)
    if s.skip_k > 0
        s.skip_k -= 1
    else
        s.value = el
        s.state *= rand(s.rng)
        s.skip_k = -ceil(Int, randexp(s.rng)/log(1-s.state))
    end
    return s
end

function itsample(iter, method::ReservoirAlgorithm = algL)
    return itsample(Random.default_rng(), iter, method)
end

function itsample(rng::AbstractRNG, iter, method::ReservoirAlgorithm = algL)
    if Base.IteratorSize(iter) isa Base.SizeUnknown
        return reservoir_sample(rng, iter, method)
    else 
        return sortedindices_sample(rng, iter)
    end
end

function reservoir_sample(rng, iter, method::ReservoirAlgorithm = algL)
    s = ReservoirSample(rng, calculate_eltype(iter), method)
    for x in iter
        update!(s, x)
    end
    return value(s)
end
