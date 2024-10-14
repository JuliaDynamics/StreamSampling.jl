
@hybrid struct SampleMultiAlgR{O,T,R} <: AbstractReservoirSample
    seen_k::Int
    const rng::R
    const value::Vector{T}
    const ord::O
end
const SampleMultiOrdAlgR = SampleMultiAlgR{<:Vector}

@hybrid struct SampleMultiAlgL{O,T,R} <: AbstractReservoirSample
    state::Float64
    skip_k::Int
    seen_k::Int
    const rng::R
    const value::Vector{T}
    const ord::O
end
const SampleMultiOrdAlgL = SampleMultiAlgL{<:Vector}

@hybrid struct SampleMultiAlgRSWRSKIP{O,T,R} <: AbstractReservoirSample
    skip_k::Int
    seen_k::Int
    const rng::R
    const value::Vector{T}
    const ord::O
end
const SampleMultiOrdAlgRSWRSKIP = SampleMultiAlgRSWRSKIP{<:Vector}

function ReservoirSample{T}(rng::AbstractRNG, n::Integer, ::AlgL, ::MutSample, ::Ord) where T
    return SampleMultiAlgL_Mut(0.0, 0, 0, rng, Vector{T}(undef, n), collect(1:n))
end
function ReservoirSample{T}(rng::AbstractRNG, n::Integer, ::AlgL, ::MutSample, ::Unord) where T
    return SampleMultiAlgL_Mut(0.0, 0, 0, rng, Vector{T}(undef, n), nothing)
end
function ReservoirSample{T}(rng::AbstractRNG, n::Integer, ::AlgL, ::ImmutSample, ::Ord) where T
    return SampleMultiAlgL_Immut(0.0, 0, 0, rng, Vector{T}(undef, n), collect(1:n))
end
function ReservoirSample{T}(rng::AbstractRNG, n::Integer, ::AlgL, ::ImmutSample, ::Unord) where T
    return SampleMultiAlgL_Immut(0.0, 0, 0, rng, Vector{T}(undef, n), nothing)
end
function ReservoirSample{T}(rng::AbstractRNG, n::Integer, ::AlgR, ::MutSample, ::Ord) where T
    return SampleMultiAlgR_Mut(0, rng, Vector{T}(undef, n), collect(1:n))
end        
function ReservoirSample{T}(rng::AbstractRNG, n::Integer, ::AlgR, ::MutSample, ::Unord) where T
    return SampleMultiAlgR_Mut(0, rng, Vector{T}(undef, n), nothing)
end
function ReservoirSample{T}(rng::AbstractRNG, n::Integer, ::AlgR, ::ImmutSample, ::Ord) where T
    return SampleMultiAlgR_Immut(0, rng, Vector{T}(undef, n), collect(1:n))
end
function ReservoirSample{T}(rng::AbstractRNG, n::Integer, ::AlgR, ::ImmutSample, ::Unord) where T
    return SampleMultiAlgR_Immut(0, rng, Vector{T}(undef, n), nothing)
end
function ReservoirSample{T}(rng::AbstractRNG, n::Integer, ::AlgRSWRSKIP, ::MutSample, ::Ord) where T
    return SampleMultiAlgRSWRSKIP_Mut(0, 0, rng, Vector{T}(undef, n), collect(1:n))
end
function ReservoirSample{T}(rng::AbstractRNG, n::Integer, ::AlgRSWRSKIP, ::MutSample, ::Unord) where T
    return SampleMultiAlgRSWRSKIP_Mut(0, 0, rng, Vector{T}(undef, n), nothing)
end
function ReservoirSample{T}(rng::AbstractRNG, n::Integer, ::AlgRSWRSKIP, ::ImmutSample, ::Ord) where T
    return SampleMultiAlgRSWRSKIP_Immut(0, 0, rng, Vector{T}(undef, n), collect(1:n))
end
function ReservoirSample{T}(rng::AbstractRNG, n::Integer, ::AlgRSWRSKIP, ::ImmutSample, ::Unord) where T
    return SampleMultiAlgRSWRSKIP_Immut(0, 0, rng, Vector{T}(undef, n), nothing)
end

@inline function OnlineStatsBase._fit!(s::SampleMultiAlgR, el)
    n = length(s.value)
    s = @inline update_state!(s)
    if s.seen_k <= n
        @inbounds s.value[s.seen_k] = el
    else
        j = rand(s.rng, 1:s.seen_k)
        if j <= n
            @inbounds s.value[j] = el
            update_order!(s, j)
        end
    end
    return s
end
@inline function OnlineStatsBase._fit!(s::SampleMultiAlgL, el)
    n = length(s.value)
    s = @inline update_state!(s)
    if s.seen_k <= n
        @inbounds s.value[s.seen_k] = el
        if s.seen_k === n
            s = @inline recompute_skip!(s, n)
        end
    elseif s.skip_k < s.seen_k
        j = rand(s.rng, 1:n)
        @inbounds s.value[j] = el
        update_order!(s, j)
        s = @inline recompute_skip!(s, n)
    end
    return s
end
@inline function OnlineStatsBase._fit!(s::SampleMultiAlgRSWRSKIP, el)
    n = length(s.value)
    s = @inline update_state!(s)
    if s.seen_k <= n
        @inbounds s.value[s.seen_k] = el
        if s.seen_k === n
            s = recompute_skip!(s, n)
            new_values = sample(s.rng, s.value, n, ordered=is_ordered(s))
            @inbounds for i in 1:n
                s.value[i] = new_values[i]
            end
        end
    elseif s.skip_k < s.seen_k
        p = 1/s.seen_k
        z = exp((n-4)*log1p(-p))
        q = rand(s.rng, Uniform(z*(1-p)*(1-p)*(1-p)*(1-p),1.0))
        k = @inline choose(n, p, q, z)
        @inbounds for j in 1:k
            r = rand(s.rng, j:n)
            s.value[r], s.value[j] = s.value[j], el
            update_order_multi!(s, r, j)
        end
        s = recompute_skip!(s, n)
    end
    return s
end

function Base.empty!(s::SampleMultiAlgR_Mut)
    s.seen_k = 0
    return s
end
function Base.empty!(s::SampleMultiAlgL_Mut)
    s.state = 0.0
    s.skip_k = 0
    s.seen_k = 0
    return s
end
function Base.empty!(s::SampleMultiAlgRSWRSKIP_Mut)
    s.skip_k = 0
    s.seen_k = 0
    return s
end

function update_state!(s::SampleMultiAlgR)
    @update s.seen_k += 1
    return s
end
function update_state!(s::SampleMultiAlgL)
    @update s.seen_k += 1
    return s
end
function update_state!(s::SampleMultiAlgRSWRSKIP)
    @update s.seen_k += 1
    return s
end

function recompute_skip!(s::SampleMultiAlgL, n)
    @update s.state += randexp(s.rng)
    @update s.skip_k = s.seen_k-ceil(Int, randexp(s.rng)/log(1-exp(-s.state/n)))
    return s
end
function recompute_skip!(s::SampleMultiAlgRSWRSKIP, n)
    q = exp(-randexp(s.rng)/n)
    @update s.skip_k = ceil(Int, s.seen_k/q)-1
    return s
end

function choose(n, p, q, z)
    m = 1-p
    s = z
    z = s*m*m*m*(m + n*p)
    z > q && return 1
    z += n*p*(n-1)*p*s*m*m/2
    z > q && return 2
    z += n*p*(n-1)*p*(n-2)*p*s*m/6
    z > q && return 3
    z += n*p*(n-1)*p*(n-2)*p*(n-3)*p*s/24
    z > q && return 4
    b = Binomial(n, p)
    return quantile(b, q)
end

update_order!(s::Union{SampleMultiAlgR, SampleMultiAlgL}, j) = nothing
function update_order!(s::Union{SampleMultiOrdAlgR, SampleMultiOrdAlgL}, j)
    s.ord[j] = nobs(s)
end

update_order_single!(s::SampleMultiAlgRSWRSKIP, r) = nothing
function update_order_single!(s::SampleMultiOrdAlgRSWRSKIP, r)
    s.ord[r] = nobs(s)
end

update_order_multi!(s::SampleMultiAlgRSWRSKIP, r, j) = nothing
function update_order_multi!(s::SampleMultiOrdAlgRSWRSKIP, r, j)
    s.ord[r], s.ord[j] = s.ord[j], nobs(s)
end

is_ordered(s::SampleMultiOrdAlgRSWRSKIP) = true
is_ordered(s::SampleMultiAlgRSWRSKIP) = false

function Base.merge(ss::SampleMultiAlgRSWRSKIP...)
    newvalue = reduce_samples(TypeUnion(), ss...)
    skip_k = sum(getfield(s, :skip_k) for s in ss)
    seen_k = sum(getfield(s, :seen_k) for s in ss)
    return SampleMultiAlgRSWRSKIP_Mut(skip_k, seen_k, ss[1].rng, newvalue, nothing)
end

function Base.merge!(s1::SampleMultiAlgRSWRSKIP{<:Nothing}, ss::SampleMultiAlgRSWRSKIP...)
    newvalue = reduce_samples(TypeS(), s1, ss...)
    for i in 1:length(newvalue)
        @inbounds s1.value[i] = newvalue[i]
    end
    s1.skip_k += sum(getfield(s, :skip_k) for s in ss)
    s1.seen_k += sum(getfield(s, :seen_k) for s in ss)
    return s1
end

function OnlineStatsBase.value(s::Union{SampleMultiAlgR, SampleMultiAlgL})
    if nobs(s) < length(s.value)
        return s.value[1:nobs(s)]
    else
        return s.value
    end
end
function OnlineStatsBase.value(s::SampleMultiAlgRSWRSKIP)
    if nobs(s) < length(s.value)
        if nobs(s) == 0
            return s.value[1:0]
        else
            return sample(s.rng, s.value[1:nobs(s)], length(s.value))
        end
    else
        return s.value
    end
end

function ordvalue(s::Union{SampleMultiOrdAlgR, SampleMultiOrdAlgL})
    if nobs(s) < length(s.value)
        return s.value[1:nobs(s)]
    else
        return s.value[sortperm(s.ord)]
    end
end
function ordvalue(s::SampleMultiOrdAlgRSWRSKIP)
    if nobs(s) < length(s.value)
        if nobs(s) == 0
            return s.value[1:0]
        else
            return sample(s.rng, s.value[1:nobs(s)], length(s.value); ordered=true)
        end
    else
        return s.value[sortperm(s.ord)]
    end
end
