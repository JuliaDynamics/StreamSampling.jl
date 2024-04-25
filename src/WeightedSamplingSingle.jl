
mutable struct SampleSingleAlgARes{T,R} <: AbstractWeightedReservoirSampleSingle
    state::Float64
    const rng::R
    value::T
    SampleSingleAlgARes{T,R}(state, rng) where {T,R} = new{T,R}(state, rng)
end

mutable struct SampleSingleAlgAExpJ{T,R} <: AbstractWeightedReservoirSampleSingle
    state::Float64
    skip_w::Float64
    const rng::R
    value::T
    SampleSingleAlgAExpJ{T,R}(state, skip_w, rng) where {T,R} = new{T,R}(state, skip_w, rng)
end

function ReservoirSample(rng::R, T, method::AlgARes) where {R<:AbstractRNG}
    return SampleSingleAlgARes{T,R}(0.0, rng)
end
function ReservoirSample(rng::R, T, method::AlgAExpJ) where {R<:AbstractRNG}
    return SampleSingleAlgAExpJ{T,R}(0.0, 0.0, rng)
end

function value(s::AbstractWeightedReservoirSampleSingle)
    s.state === 0.0 && return nothing
    return s.value
end

@inline function update!(s::SampleSingleAlgARes, el, w)
    priority = -randexp(s.rng)/w
    if priority > s.state
        @imm_reset s.state = priority
        @imm_reset s.value = el
    end
    return s
end
@inline function update!(s::SampleSingleAlgAExpJ, el, weight)
    @imm_reset s.state += weight
    if s.skip_w <= s.state
        @imm_reset s.value = el
        @imm_reset s.skip_w = s.state/rand(s.rng)
    end
    return s
end

function itsample(iter, wv::Function, method::ReservoirAlgorithm = algAExpJ)
    return itsample(Random.default_rng(), iter, wv, method)
end

function itsample(rng::AbstractRNG, iter, wv::Function, method::ReservoirAlgorithm = algAExpJ)
    s = ReservoirSample(rng, calculate_eltype(iter), algAExpJ)
    for x in iter
        s = update!(s, x, wv(x))
    end
    return value(s)
end
