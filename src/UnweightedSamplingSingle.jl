
@hybrid struct RefVal{T}
    value::T
    RefVal{T}() where T = new{T}()
    RefVal(value::T) where T = new{T}(value)
end

@hybrid struct SampleSingleAlgR{RT,R} <: AbstractReservoirSampleSingle
    seen_k::Int
    skip_k::Int
    const rng::R
    rvalue::RT
end

function OnlineStatsBase.value(s::SampleSingleAlgR)
    s.seen_k === 0 && return nothing
    return s.rvalue.value
end

function ReservoirSample(T, method::ReservoirAlgorithm = AlgR())
    return ReservoirSample(Random.default_rng(), T, method, MutSample())
end
function ReservoirSample(rng::AbstractRNG, T, method::ReservoirAlgorithm = AlgR())
    return ReservoirSample(rng, T, method, MutSample())
end
function ReservoirSample(rng::AbstractRNG, T, ::AlgR, ::MutSample)
    return SampleSingleAlgR_Mut(0, 0, rng, RefVal_Immut{T}())
end
function ReservoirSample(rng::AbstractRNG, T, ::AlgR, ::ImmutSample)
    return SampleSingleAlgR_Immut(0, 0, rng, RefVal_Mut{T}())
end
function ReservoirSample(rng::AbstractRNG, T, ::AlgL, ::ImmutSample)
    return SampleSingleAlgR_Immut(0, 0, rng, RefVal_Mut{T}())
end

@inline function OnlineStatsBase._fit!(s::SampleSingleAlgR, el)
    @update s.seen_k += 1
    if s.skip_k <= s.seen_k
        @update s.skip_k = ceil(Int, s.seen_k/rand(s.rng))
        reset_value!(s, el)
    end
    return s
end

function reset_value!(s::SampleSingleAlgR_Mut, el)
    s.rvalue = RefVal_Immut(el)
end
function reset_value!(s::SampleSingleAlgR_Immut, el)
    s.rvalue.value = el
end

function Base.empty!(s::SampleSingleAlgR)
    s.seen_k = 0
    s.skip_k = 0
    return s
end

function Base.merge(s1::AbstractReservoirSampleSingle, s2::AbstractReservoirSampleSingle)
    n1, n2 = nobs(s1), nobs(s2)
    n_tot = n1 + n2
    value = rand(s1.rng) < n1/n_tot ? s1.rvalue : s2.rvalue
    return typeof(s1)(n_tot, s1.skip_k + s2.skip_k, s1.rng, value)
end

function Base.merge!(s1::SampleSingleAlgR_Mut, s2::SampleSingleAlgR_Mut)
    n1, n2 = nobs(s1), nobs(s2)
    n_tot = n1 + n2
    r = rand(s1.rng)
    p = n2 / n_tot
    if r < p
        s1.rvalue = RefVal_Immut(s2.rvalue.value)
    end
    s1.seen_k = n_tot
    s1.skip_k += s2.skip_k
    return s1
end

function reservoir_sample(rng, iter, iter_type, method::ReservoirAlgorithm = algR)
    s = ReservoirSample(rng, iter_type, method, ims)
    return update_all!(s, iter)
end

function update_all!(s, iter)
    for x in iter
        s = fit!(s, x)
    end
    return value(s)
end
