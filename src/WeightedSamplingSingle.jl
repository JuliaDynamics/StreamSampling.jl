
mutable struct WeightedResSampleSingle{T} <: AbstractReservoirSample
    state::Float64
    skip_w::Float64
    value::T
    WeightedResSampleSingle{T}(state, skip_w) where T = new{T}(state, skip_w)
end

function WeightedReservoirSample(T)
    return WeightedResSampleSingle{T}(0.0, 0.0)
end

function value(s::WeightedResSampleSingle)
    s.state === 0.0 && return nothing
    return s.value
end

update!(s::WeightedResSampleSingle, el, weight) = update!(Random.default_rng(), s, el, weight)
function update!(rng, s::WeightedResSampleSingle, el, weight)
    s.state += weight
    if s.skip_w < s.state
        s.value = el
        s.skip_w = skip(rng, s.state, 1)
    end
    return s
end

function itsample(iter, wv::Function)
    return itsample(Random.default_rng(), iter, wv)
end

function itsample(rng::AbstractRNG, iter, wv::Function)
    s = WeightedReservoirSample(Base.@default_eltype(iter))
    for x in iter
        @inline update!(rng, s, x, wv(x))
    end
    return value(s)
end
