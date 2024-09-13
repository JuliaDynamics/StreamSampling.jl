
mutable struct SampleSingleAlgL{T,R} <: AbstractReservoirSampleSingle
    state::Float64
    seen_k::Int
    skip_k::Int
    const rng::R
    value::T
    SampleSingleAlgL{T,R}(state, seen_k, skip_k, rng) where {T,R} = new{T,R}(state, seen_k, skip_k, rng)
end

mutable struct SampleSingleAlgR{T,R} <: AbstractReservoirSampleSingle
    seen_k::Int
    skip_k::Int
    const rng::R
    value::T
    SampleSingleAlgR{T,R}(seen_k, rng, value) where {T,R} = new{T,R}(seen_k, rng, value)
    SampleSingleAlgR{T,R}(seen_k, rng) where {T,R} = new{T,R}(seen_k, rng)
end

function value(s::SampleSingleAlgL)
    s.state === 1.0 && return nothing
    return s.value
end
function value(s::SampleSingleAlgR)
    s.seen_k === 0 && return nothing
    return s.value
end

function ReservoirSample(T, method::ReservoirAlgorithm = algR)
    return ReservoirSample(Random.default_rng(), T, method, ms)
end
function ReservoirSample(rng::AbstractRNG, T, method::ReservoirAlgorithm = algR)
    return ReservoirSample(rng, T, method, ms)
end
function ReservoirSample(rng::AbstractRNG, T, ::AlgL, ::MutSample)
    return SampleSingleAlgL{T, typeof(rng)}(1.0, 0, 0, rng)
end
function ReservoirSample(rng::AbstractRNG, T, ::AlgR, ::MutSample)
    return SampleSingleAlgR{T, typeof(rng)}(0, 0, rng)
end

@inline function update!(s::SampleSingleAlgR, el)
    s.seen_k += 1
    if s.skip_k <= s.seen_k
        s.skip_k = ceil(Int, s.seen_k/rand(s.rng))
        s.value = el
    end
    return s
end
@inline function update!(s::SampleSingleAlgL, el)
    s.seen_k += 1
    if s.skip_k > 0
        s.skip_k -= 1
    else
        s.value = el
        s.state *= rand(s.rng)
        s.skip_k = -ceil(Int, randexp(s.rng)/log(1-s.state))
    end
    return s
end

function reset!(s::SampleSingleAlgL)
    s.state = 1.0
    s.seen_k = 0
    s.skip_k = 0
    return s
end
function reset!(s::SampleSingleAlgR)
    s.seen_k = 0
    s.skip_k = 0
    return s
end

function Base.merge(s1::AbstractReservoirSampleSingle, s2::AbstractReservoirSampleSingle)
    n1, n2 = n_seen(s1), n_seen(s2)
    n_tot = n1 + n2
    value = rand(s1.rng) < n1/n_tot ? s1.value : s2.value
    return SampleSingleAlgR{typeof(value), typeof(s1.rng)}(n_tot, s1.rng, value)
end

function Base.merge!(s1::SampleSingleAlgR, s2::AbstractReservoirSampleSingle)
    n1, n2 = n_seen(s1), n_seen(s2)
    n_tot = n1 + n2
    r = rand(s1.rng)
    p = n2 / n_tot
    if r < p
        s1.value = s2.value
    end
    s1.seen_k = n_tot
    return s1
end

function itsample(iter, method::ReservoirAlgorithm = algR;
        iter_type = infer_eltype(iter))
    return itsample(Random.default_rng(), iter, method; iter_type)
end
function itsample(rng::AbstractRNG, iter, method::ReservoirAlgorithm = algR;
        iter_type = infer_eltype(iter))
    if Base.IteratorSize(iter) isa Base.SizeUnknown
        return reservoir_sample(rng, iter, iter_type, method)
    else 
        return sortedindices_sample(rng, iter)
    end
end

function reservoir_sample(rng, iter, iter_type, method::ReservoirAlgorithm = algR)
    s = ReservoirSample(rng, iter_type, method)
    return update_all!(s, iter)
end

function update_all!(s, iter)
    for x in iter
        s = update!(s, x)
    end
    return value(s)
end
