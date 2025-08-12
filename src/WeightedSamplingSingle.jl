
@hybrid struct SingleAlgWRSWRSKIPSampler{RT,R,F} <: AbstractWeightedReservoirSampler
    seen_k::Int
    total_w::F
    skip_w::F
    const rng::R
    rvalue::RT
end

function ReservoirSampler{T,F}(rng::AbstractRNG, ::AlgWRSWRSKIP, ::MutSampler) where {T,F}
    return SingleAlgWRSWRSKIPSampler_Mut(0, zero(F), zero(F), rng, RefVal_Immut{T}())
end
function ReservoirSampler{T,F}(rng::AbstractRNG, ::AlgWRSWRSKIP, ::ImmutSampler) where {T,F}
    return SingleAlgWRSWRSKIPSampler_Immut(0, zero(F), zero(F), rng, RefVal_Mut{T}())
end

function OnlineStatsBase.value(s::SingleAlgWRSWRSKIPSampler)
    s.seen_k === 0 && return nothing
    return get_value(s)
end

@inline function OnlineStatsBase._fit!(s::SingleAlgWRSWRSKIPSampler, el, w)
    @update s.seen_k += 1
    @update s.total_w += w
    if s.skip_w <= s.total_w
        @update s.skip_w = s.total_w/rand(s.rng)
        reset_value!(s, el)
    end
    return s
end

function Base.empty!(s::SingleAlgWRSWRSKIPSampler_Mut)
    s.seen_k = 0
    s.total_w = 0.0
    s.skip_w = 0.0
    return s
end

get_value(s::SingleAlgWRSWRSKIPSampler) = s.rvalue.value

function reset_value!(s::SingleAlgWRSWRSKIPSampler_Mut, el)
    s.rvalue = RefVal_Immut(el)
end
function reset_value!(s::SingleAlgWRSWRSKIPSampler_Immut, el)
    s.rvalue.value = el
end

function Base.merge(ss::SingleAlgWRSWRSKIPSampler...)
    ns = [s.total_w for s in ss]
    n_tot = sum(ns)
    ps = cumsum(ns ./ n_tot)
    r = rand(s1.rng)
    value = ss[findfirst(p -> r < p, ps)].value
    return typeof(s1)(sum(s.seen_k for s in ss), sum(s.total_w for s in ss), sum(s.skip_w for s in ss), 
                      ss[1].rng, value)
end

function Base.merge!(s1::SingleAlgWRSWRSKIPSampler_Mut, ss::SingleAlgWRSWRSKIPSampler_Mut...)
    ns = [s1.total_w, [s.total_w for s in ss]...]
    n_tot = sum(ns)
    ps = cumsum(ns ./ n_tot)
    r = rand(s1.rng)
    i = findfirst(p -> r < p, ps)
    if i > 1
        s1.rvalue = RefVal_Immut(ss[i-1].rvalue.value)
    end
    s1.seen_k += sum(s.seen_k for s in ss)
    s1.skip_w += sum(s.skip_w for s in ss)
    s1.total_w += sum(s.total_w for s in ss)
    return s1
end

