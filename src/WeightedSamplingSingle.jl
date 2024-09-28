
@hybrid struct SampleSingleAlgAExpJ{RT,R,F} <: AbstractWeightedReservoirSampleSingle
    seen_k::Int
    total_w::Float64
    skip_w::Float64
    const rng::R
    rvalue::RT
    wv::F
end

function ReservoirSample(T, wv, method::ReservoirAlgorithm = AlgR())
    return ReservoirSample(Random.default_rng(), T, wv, method, MutSample())
end
function ReservoirSample(rng::R, T, wv, ::AlgAExpJ, ::MutSample) where {R<:AbstractRNG}
    return SampleSingleAlgAExpJ_Mut(0, 0.0, 0.0, rng, RefVal_Immut{T}(), wv)
end
function ReservoirSample(rng::R, T, wv, ::AlgAExpJ, ::ImmutSample) where {R<:AbstractRNG}
    return SampleSingleAlgAExpJ_Immut(0, 0.0, 0.0, rng, RefVal_Mut{T}(), wv)
end

function OnlineStatsBase.value(s::AbstractWeightedReservoirSampleSingle)
    s.seen_k === 0 && return nothing
    return get_value(s)
end

@inline function OnlineStatsBase._fit!(s::SampleSingleAlgAExpJ, el)
    @update s.seen_k += 1
    weight = s.wv(el)
    @update s.total_w += weight
    if s.skip_w <= s.total_w
        @update s.skip_w = s.total_w/rand(s.rng)
        reset_value!(s, el)
    end
    return s
end

function Base.empty!(s::SampleSingleAlgAExpJ_Mut)
    s.seen_k = 0
    s.total_w = 0.0
    s.skip_w = 0.0
    return s
end

get_value(s::SampleSingleAlgAExpJ) = s.rvalue.value

function reset_value!(s::SampleSingleAlgAExpJ_Mut, el)
    s.rvalue = RefVal_Immut(el)
end
function reset_value!(s::SampleSingleAlgAExpJ_Immut, el)
    s.rvalue.value = el
end
