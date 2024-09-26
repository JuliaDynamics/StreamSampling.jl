
mutable struct RefVal{T}
    value::T
    RefVal{T}() where T = new{T}()
    RefVal(value::T) where T = new{T}(value)
end

struct ImmutSampleSingleAlgAExpJ{T,R} <: AbstractWeightedReservoirSampleSingle
    seen_k::Int
    total_w::Float64
    skip_w::Float64
    rng::R
    rvalue::RefVal{T}
end
mutable struct MutSampleSingleAlgAExpJ{T,R} <: AbstractWeightedReservoirSampleSingle
    seen_k::Int
    total_w::Float64
    skip_w::Float64
    const rng::R
    value::T
    MutSampleSingleAlgAExpJ{T,R}(seen_k, total_w, skip_w, rng) where {T,R} = new{T,R}(seen_k, total_w, skip_w, rng)
end
const SampleSingleAlgAExpJ = Union{ImmutSampleSingleAlgAExpJ, MutSampleSingleAlgAExpJ}

function ReservoirSample(rng::R, T, ::AlgAExpJ, ::MutSample) where {R<:AbstractRNG}
    return MutSampleSingleAlgAExpJ{T,R}(0, 0.0, 0.0, rng)
end
function ReservoirSample(rng::R, T, ::AlgAExpJ, ::ImmutSample) where {R<:AbstractRNG}
    return ImmutSampleSingleAlgAExpJ(0, 0.0, 0.0, rng, RefVal{T}())
end

function value(s::AbstractWeightedReservoirSampleSingle)
    s.seen_k === 0 && return nothing
    return get_value(s)
end

@inline function update!(s::SampleSingleAlgAExpJ, el, weight)
    @reset s.seen_k += 1
    @reset s.total_w += weight
    if s.skip_w <= s.total_w
        @reset s.skip_w = s.total_w/rand(s.rng)
        s = reset_value!(s, el)
    end
    return s
end

function Base.empty!(s::MutSampleSingleAlgAExpJ)
    s.seen_k = 0
    s.total_w = 0.0
    s.skip_w = 0.0
    return s
end

get_value(s::MutSampleSingleAlgAExpJ) = s.value
get_value(s::ImmutSampleSingleAlgAExpJ) = s.rvalue.value

function reset_value!(s::MutSampleSingleAlgAExpJ, el)
    s.value = el
    return s
end
function reset_value!(s::ImmutSampleSingleAlgAExpJ, el)
    @reset s.rvalue.value = el
    return s
end

function update_all!(s, iter, wv::Function)
    for x in iter
        s = update!(s, x, wv(x))
    end
    return value(s)
end
