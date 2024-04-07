
mutable struct ResSampleSingleAlgL{T} <: AbstractReservoirSample
    state::Float64
    skip_k::Int
    value::T
    ResSampleSingleAlgL{T}(state, skip_k) where T = new{T}(state, skip_k)
end

mutable struct ResSampleSingleAlgR{T} <: AbstractReservoirSample
    state::Int
    value::T
    ResSampleSingleAlgR{T}(state) where T = new{T}(state)
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
    if method === :alg_L
        return ResSampleSingleAlgL{T}(1.0, 0)
    else
        return ResSampleSingleAlgR{T}(0)
    end
end

update!(s::ResSampleSingleAlgR, el) = update!(Random.default_rng(), s, el)
function update!(rng, s::ResSampleSingleAlgR, el)
    s.state += 1
    if rand(rng) <= 1/s.state
        s.value = el
    end
    return s
end

update!(s::ResSampleSingleAlgL, el) = update!(Random.default_rng(), s, el)
function update!(rng, s::ResSampleSingleAlgL, el)
    if s.skip_k > 0
        s.skip_k -= 1
    else
        s.value = el
        s.state *= rand(rng)
        s.skip_k = -ceil(Int, randexp(rng)/log(1-s.state))
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
    s = ReservoirSample(Base.@default_eltype(iter); method = method)
    for x in iter
        @inline update!(rng, s, x)
    end
    return s.value
end

function sortedindices_sample(rng, iter; kwargs...)
    k = rand(rng, 1:length(iter))
    for (i, el) in enumerate(iter)
        i == k && return el
    end
end
