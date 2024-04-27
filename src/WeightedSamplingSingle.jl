
mutable struct RefVal{T}
    value::T
    RefVal{T}() where T = new{T}()
    RefVal(value::T) where T = new{T}(value)
end

struct ImmutSampleSingleAlgARes{T,R} <: AbstractWeightedReservoirSampleSingle
    state::Float64
    rng::R
    rvalue::RefVal{T}
end
mutable struct MutSampleSingleAlgARes{T,R} <: AbstractWeightedReservoirSampleSingle
    state::Float64
    const rng::R
    value::T
    MutSampleSingleAlgARes{T,R}(state, rng) where {T,R} = new{T,R}(state, rng)
end
const SampleSingleAlgARes = Union{ImmutSampleSingleAlgARes, MutSampleSingleAlgARes}

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

function ReservoirSample(rng::R, T, ::AlgARes, ::MutSample) where {R<:AbstractRNG}
    return MutSampleSingleAlgARes{T,R}(typemax(Float64), rng)
end
function ReservoirSample(rng::R, T, ::AlgARes, ::ImmutSample) where {R<:AbstractRNG}
    return ImmutSampleSingleAlgARes(typemax(Float64), rng, RefVal{T}())
end
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

@inline function update!(s::SampleSingleAlgARes, el, w)
    priority = randexp(s.rng)/w
    if priority < s.state
        @imm_reset s.state = priority
        s = set_val(s, el)
    end
    return s
end
@inline function update!(s::SampleSingleAlgAExpJ, el, weight)
    @imm_reset s.state += weight
    if s.skip_w <= s.state
        @imm_reset s.skip_w = s.state/rand(s.rng)
        s = set_val(s, el)
    end
    return s
end

get_val(s::Union{ImmutSampleSingleAlgARes, ImmutSampleSingleAlgAExpJ}) = s.rvalue.value
function set_val(s::Union{ImmutSampleSingleAlgARes, ImmutSampleSingleAlgAExpJ}, el)
    @reset s.rvalue.value = el
    return s
end
get_val(s::Union{MutSampleSingleAlgARes, MutSampleSingleAlgAExpJ}) = s.value
function set_val(s::Union{MutSampleSingleAlgARes, MutSampleSingleAlgAExpJ}, el)
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
