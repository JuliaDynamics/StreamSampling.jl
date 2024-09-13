
mutable struct RefVal{T}
    value::T
    RefVal{T}() where T = new{T}()
    RefVal(value::T) where T = new{T}(value)
end

struct ImmutSampleSingleAlgAExpJ{T,R} <: AbstractWeightedReservoirSampleSingle
    state::Float64
    skip_w::Float64
    rng::R
    rvalue::RefVal{T}
end
mutable struct MutSampleSingleAlgAExpJ{T,R} <: AbstractWeightedReservoirSampleSingle
    state::Float64
    skip_w::Float64
    const rng::R
    value::T
    MutSampleSingleAlgAExpJ{T,R}(state, skip_w, rng) where {T,R} = new{T,R}(state, skip_w, rng)
end
const SampleSingleAlgAExpJ = Union{ImmutSampleSingleAlgAExpJ, MutSampleSingleAlgAExpJ}

function ReservoirSample(rng::R, T, ::AlgAExpJ, ::MutSample) where {R<:AbstractRNG}
    return MutSampleSingleAlgAExpJ{T,R}(0.0, 0.0, rng)
end
function ReservoirSample(rng::R, T, ::AlgAExpJ, ::ImmutSample) where {R<:AbstractRNG}
    return ImmutSampleSingleAlgAExpJ(0.0, 0.0, rng, RefVal{T}())
end

function value(s::AbstractWeightedReservoirSampleSingle)
    s.state === 0.0 && return nothing
    return get_val(s)
end

@inline function update!(s::SampleSingleAlgAExpJ, el, weight)
    @imm_reset s.state += weight
    if s.skip_w <= s.state
        @imm_reset s.skip_w = s.state/rand(s.rng)
        s = set_val(s, el)
    end
    return s
end

function reset!(s::MutSampleSingleAlgAExpJ)
    s.state = 0.0
    s.skip_w = 0.0
    return s
end

get_val(s::ImmutSampleSingleAlgAExpJ) = s.rvalue.value
function set_val(s::ImmutSampleSingleAlgAExpJ, el)
    @reset s.rvalue.value = el
    return s
end
get_val(s::MutSampleSingleAlgAExpJ) = s.value
function set_val(s::MutSampleSingleAlgAExpJ, el)
    s.value = el
    return s
end

function itsample(iter, wv::Function, method::ReservoirAlgorithm = algAExpJ;
        iter_type = infer_eltype(iter))
    return itsample(Random.default_rng(), iter, wv, method)
end

function itsample(rng::AbstractRNG, iter, wv::Function, method::ReservoirAlgorithm = algAExpJ;
        iter_type = infer_eltype(iter))
    s = ReservoirSample(rng, iter_type, method, ims)
    return update_all!(s, iter, wv)
end

function update_all!(s, iter, wv::Function)
    for x in iter
        s = update!(s, x, wv(x))
    end
    return value(s)
end
