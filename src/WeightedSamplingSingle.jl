
@hybrid struct SampleSingleAlgWRSWRSKIP{RT,R} <: AbstractReservoirSampler
    seen_k::Int
    total_w::Float64
    skip_w::Float64
    const rng::R
    rvalue::RT
end

function ReservoirSampler{T}(rng::AbstractRNG, ::AlgWRSWRSKIP, ::MutSample) where T
    return SampleSingleAlgWRSWRSKIP_Mut(0, 0.0, 0.0, rng, RefVal_Immut{T}())
end
function ReservoirSampler{T}(rng::AbstractRNG, ::AlgWRSWRSKIP, ::ImmutSample) where T
    return SampleSingleAlgWRSWRSKIP_Immut(0, 0.0, 0.0, rng, RefVal_Mut{T}())
end

function OnlineStatsBase.value(s::SampleSingleAlgWRSWRSKIP)
    s.seen_k === 0 && return nothing
    return get_value(s)
end

@inline function OnlineStatsBase._fit!(s::SampleSingleAlgWRSWRSKIP, el, w)
    @update s.seen_k += 1
    @update s.total_w += w
    if s.skip_w <= s.total_w
        @update s.skip_w = s.total_w/rand(s.rng)
        reset_value!(s, el)
    end
    return s
end

function Base.empty!(s::SampleSingleAlgWRSWRSKIP_Mut)
    s.seen_k = 0
    s.total_w = 0.0
    s.skip_w = 0.0
    return s
end

get_value(s::SampleSingleAlgWRSWRSKIP) = s.rvalue.value

function reset_value!(s::SampleSingleAlgWRSWRSKIP_Mut, el)
    s.rvalue = RefVal_Immut(el)
end
function reset_value!(s::SampleSingleAlgWRSWRSKIP_Immut, el)
    s.rvalue.value = el
end
