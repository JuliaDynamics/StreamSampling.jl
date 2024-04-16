
mutable struct WeightedResSampleSingle{T,R} <: AbstractReservoirSample
    state::Float64
    skip_w::Float64
    rng::R
    value::T
    WeightedResSampleSingle{T,R}(state, skip_w, rng) where {T,R} = new{T,R}(state, skip_w, rng)
end

function ReservoirSample(rng::R, T, method::AlgAExpJ) where {R<:AbstractRNG}
    return WeightedResSampleSingle{T,R}(0.0, 0.0, rng)
end

function value(s::WeightedResSampleSingle)
    s.state === 0.0 && return nothing
    return s.value
end

function update!(s::WeightedResSampleSingle, el, weight)
    s.state += weight
    if s.skip_w < s.state
        s.value = el
        s.skip_w = skip(s.rng, s.state, 1)
    end
    return s
end

function itsample(iter, wv::Function)
    return itsample(Random.default_rng(), iter, wv)
end

function itsample(rng::AbstractRNG, iter, wv::Function)
    s = ReservoirSample(rng, Base.@default_eltype(iter), algAExpJ)
    for x in iter
        @inline update!(s, x, wv(x))
    end
    return value(s)
end
