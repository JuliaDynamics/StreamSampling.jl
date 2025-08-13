
@hybrid struct SingleAlgRSWRSKIPSampler{RT,R} <: AbstractReservoirSampler
    seen_k::Int
    skip_k::Int
    const rng::R
    rvalue::RT
end

function ReservoirSampler{T,F}(rng::AbstractRNG, ::AlgRSWRSKIP, ::MutSampler) where {T,F}
    return SingleAlgRSWRSKIPSampler_Mut(0, 0, rng, RefVal_Immut{T}())
end
function ReservoirSampler{T,F}(rng::AbstractRNG, ::AlgRSWRSKIP, ::ImmutSampler) where {T,F}
    return SingleAlgRSWRSKIPSampler_Immut(0, 0, rng, RefVal_Mut{T}())
end

function OnlineStatsBase.value(s::SingleAlgRSWRSKIPSampler)
    s.seen_k === 0 && return nothing
    return s.rvalue.value
end

@inline function OnlineStatsBase._fit!(s::SingleAlgRSWRSKIPSampler, el)
    @update s.seen_k += 1
    if s.skip_k <= s.seen_k
        @update s.skip_k = ceil(Int, s.seen_k/rand(s.rng))
        reset_value!(s, el)
    end
    return s
end

function reset_value!(s::SingleAlgRSWRSKIPSampler_Mut, el)
    s.rvalue = RefVal_Immut(el)
end
function reset_value!(s::SingleAlgRSWRSKIPSampler_Immut, el)
    s.rvalue.value = el
end

function Base.empty!(s::SingleAlgRSWRSKIPSampler)
    s.seen_k = 0
    s.skip_k = 0
    return s
end

function Base.merge(ss::SingleAlgRSWRSKIPSampler...)
    ns = [nobs(s) for s in ss]
    n_tot = sum(ns)
    ps = cumsum(ns ./ n_tot)
    r = rand(s1.rng)
    value = ss[findfirst(p -> r < p, ps)].value
    return typeof(s1)(n_tot, sum(s.skip_k for s in ss), ss[1].rng, value)
end

function Base.merge!(s1::SingleAlgRSWRSKIPSampler_Mut, ss::SingleAlgRSWRSKIPSampler_Mut...)
    ns = [nobs(s1), [nobs(s) for s in ss]...]
    n_tot = sum(ns)
    ps = cumsum(ns ./ n_tot)
    r = rand(s1.rng)
    i = findfirst(p -> r < p, ps)
    if i > 1
        s1.rvalue = RefVal_Immut(ss[i-1].rvalue.value)
    end
    s1.seen_k += sum(s.seen_k for s in ss)
    s1.skip_k += sum(s.skip_k for s in ss)
    return s1
end
