
mutable struct SampleSingleAlgAExpJ{T,R} <: AbstractReservoirSample
    state::Float64
    skip_w::Float64
    rng::R
    value::T
    SampleSingleAlgAExpJ{T,R}(state, skip_w, rng) where {T,R} = new{T,R}(state, skip_w, rng)
end

function ReservoirSample(rng::R, T, method::AlgAExpJ) where {R<:AbstractRNG}
    return SampleSingleAlgAExpJ{T,R}(0.0, 0.0, rng)
end

function value(s::SampleSingleAlgAExpJ)
    s.state === 0.0 && return nothing
    return s.value
end

@inline function update!(s::SampleSingleAlgAExpJ, el, weight)
    s.state += weight
    if s.skip_w <= s.state
        s.value = el
        s.skip_w = s.state/rand(s.rng)
    end
    return s
end

function itsample(iter, wv::Function, method::ReservoirAlgorithm = algAExpJ)
    return itsample(Random.default_rng(), iter, wv, method)
end

function itsample(rng::AbstractRNG, iter, wv::Function, method::ReservoirAlgorithm = algAExpJ)
    s = ReservoirSample(rng, Base.@default_eltype(iter), algAExpJ)
    for x in iter
        update!(s, x, wv(x))
    end
    return value(s)
end
