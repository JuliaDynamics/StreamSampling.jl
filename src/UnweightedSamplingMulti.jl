
@hybrid struct MultiAlgRSampler{O,T,R} <: AbstractReservoirSampler
    const n::Int
    seen_k::Int
    const rng::R
    const value::Vector{T}
    const ord::O
end
const MultiOrdAlgRSampler = MultiAlgRSampler{<:Memory}

@hybrid struct MultiAlgLSampler{O,T,R,F} <: AbstractReservoirSampler
    const n::Int
    state::F
    skip_k::Int
    seen_k::Int
    const rng::R
    const value::Vector{T}
    const ord::O
end
const MultiOrdAlgLSampler = MultiAlgLSampler{<:Memory}

@hybrid struct MultiAlgRSWRSKIPSampler{O,T,R} <: AbstractReservoirSampler
    const n::Int
    skip_k::Int
    seen_k::Int
    const rng::R
    const value::Vector{T}
    const ord::O
end
const MultiOrdAlgRSWRSKIPSampler = MultiAlgRSWRSKIPSampler{<:Memory}

function ReservoirSampler{T,F}(rng::AbstractRNG, n::Integer, ::AlgL, ::MutSampler, ::Ord) where {T,F}
    return MultiAlgLSampler_Mut(n, zero(F), 0, 0, rng, Vector{T}(undef, n), ordmemory(n))
end
function ReservoirSampler{T,F}(rng::AbstractRNG, n::Integer, ::AlgL, ::MutSampler, ::Unord) where {T,F}
    return MultiAlgLSampler_Mut(n, zero(F), 0, 0, rng, Vector{T}(undef, n), nothing)
end
function ReservoirSampler{T,F}(rng::AbstractRNG, n::Integer, ::AlgL, ::ImmutSampler, ::Ord) where {T,F}
    return MultiAlgLSampler_Immut(n, zero(F), 0, 0, rng, Vector{T}(undef, n), ordmemory(n))
end
function ReservoirSampler{T,F}(rng::AbstractRNG, n::Integer, ::AlgL, ::ImmutSampler, ::Unord) where {T,F}
    return MultiAlgLSampler_Immut(n, zero(F), 0, 0, rng, Vector{T}(undef, n), nothing)
end
function ReservoirSampler{T,F}(rng::AbstractRNG, n::Integer, ::AlgR, ::MutSampler, ::Ord) where {T,F}
    return MultiAlgRSampler_Mut(n, 0, rng, Vector{T}(undef, n), ordmemory(n))
end        
function ReservoirSampler{T,F}(rng::AbstractRNG, n::Integer, ::AlgR, ::MutSampler, ::Unord) where {T,F}
    return MultiAlgRSampler_Mut(n, 0, rng, Vector{T}(undef, n), nothing)
end
function ReservoirSampler{T,F}(rng::AbstractRNG, n::Integer, ::AlgR, ::ImmutSampler, ::Ord) where {T,F}
    return MultiAlgRSampler_Immut(n, 0, rng, Vector{T}(undef, n), ordmemory(n))
end
function ReservoirSampler{T,F}(rng::AbstractRNG, n::Integer, ::AlgR, ::ImmutSampler, ::Unord) where {T,F}
    return MultiAlgRSampler_Immut(n, 0, rng, Vector{T}(undef, n), nothing)
end
function ReservoirSampler{T,F}(rng::AbstractRNG, n::Integer, ::AlgRSWRSKIP, ::MutSampler, ::Ord) where {T,F}
    return MultiAlgRSWRSKIPSampler_Mut(n, 0, 0, rng, Vector{T}(undef, n), ordmemory(n))
end
function ReservoirSampler{T,F}(rng::AbstractRNG, n::Integer, ::AlgRSWRSKIP, ::MutSampler, ::Unord) where {T,F}
    return MultiAlgRSWRSKIPSampler_Mut(n, 0, 0, rng, Vector{T}(undef, n), nothing)
end
function ReservoirSampler{T,F}(rng::AbstractRNG, n::Integer, ::AlgRSWRSKIP, ::ImmutSampler, ::Ord) where {T,F}
    return MultiAlgRSWRSKIPSampler_Immut(n, 0, 0, rng, Vector{T}(undef, n), ordmemory(n))
end
function ReservoirSampler{T,F}(rng::AbstractRNG, n::Integer, ::AlgRSWRSKIP, ::ImmutSampler, ::Unord) where {T,F}
    return MultiAlgRSWRSKIPSampler_Immut(n, 0, 0, rng, Vector{T}(undef, n), nothing)
end

@inline function OnlineStatsBase._fit!(s::MultiAlgRSampler, el)
    n = s.n
    s = @inline update_state!(s)
    if s.seen_k <= n
        @inbounds s.value[s.seen_k] = el
        return s
    end
    j = rand(s.rng, Random.Sampler(s.rng, 1:s.seen_k, Val(1)))
    if j <= n
        @inbounds s.value[j] = el
        update_order!(s, j)
    end
    return s
end
@inline function OnlineStatsBase._fit!(s::MultiAlgLSampler, el)
    n = s.n
    s = @inline update_state!(s)
    if s.seen_k <= n
        @inbounds s.value[s.seen_k] = el
        if s.seen_k === n
            s = @inline recompute_skip!(s, n)
        end
        return s
    end
    if s.skip_k < s.seen_k
        j = rand(s.rng, Random.Sampler(s.rng, 1:n, Val(1)))
        @inbounds s.value[j] = el
        update_order!(s, j)
        s = @inline recompute_skip!(s, n)
    end
    return s
end
@inline function OnlineStatsBase._fit!(s::MultiAlgRSWRSKIPSampler, el)
    n = s.n
    s = @inline update_state!(s)
    if s.seen_k <= n
        @inbounds s.value[s.seen_k] = el
        if s.seen_k === n
            s = @inline recompute_skip!(s, n)
            s.value .= sample(s.rng, s.value, n, ordered=is_ordered(s))
        end
        return s
    end
    if s.skip_k < s.seen_k
        p = 1/s.seen_k
        k = @inline choose(s.rng, n, p)
        @inbounds for j in 1:k
            r = @inline rand(s.rng, Random.Sampler(s.rng, j:n, Val(1)))
            s.value[r], s.value[j] = s.value[j], el
            update_order_multi!(s, r, j)
        end 
        s = @inline recompute_skip!(s, n)
    end
    return s
end

function Base.empty!(s::MultiAlgRSampler_Mut)
    s.seen_k = 0
    return s
end
function Base.empty!(s::MultiAlgLSampler_Mut)
    s.state = 0.0
    s.skip_k = 0
    s.seen_k = 0
    return s
end
function Base.empty!(s::MultiAlgRSWRSKIPSampler_Mut)
    s.skip_k = 0
    s.seen_k = 0
    return s
end

function update_state!(s::MultiAlgRSampler)
    @update s.seen_k += 1
    return s
end
function update_state!(s::MultiAlgLSampler)
    @update s.seen_k += 1
    return s
end
function update_state!(s::MultiAlgRSWRSKIPSampler)
    @update s.seen_k += 1
    return s
end

function recompute_skip!(s::MultiAlgLSampler, n)
    @update s.state += randexp(s.rng)
    @update s.skip_k = s.seen_k-ceil(Int, randexp(s.rng)/log1p(-exp(-s.state/n)))
    return s
end
function recompute_skip!(s::MultiAlgRSWRSKIPSampler, n)
    q = exp(randexp(s.rng)/n)
    @update s.skip_k = ceil(Int, s.seen_k*q)-1
    return s
end

@inline function choose(rng, n, p)
    z = exp(n*log1p(-p))
    t = rand(rng, Uniform(z, 1.0))
    nt = t/z
    s = n*p
    q = 1-p
    x = 1 + s/q
    x > nt && return 1
    s *= (n-1)*p
    q *= 1-p
    x += s/(q*2)
    x > nt && return 2
    s *= (n-2)*p
    q *= 1-p
    x += s/(q*6)
    x > nt && return 3
    s *= (n-3)*p
    q *= 1-p
    x += s/(q*24)
    x > nt && return 4
    s *= (n-4)*p
    q *= 1-p
    x += s/(q*120)
    x > nt && return 5
    return quantile(Binomial(n, p), t)
end

update_order!(s::Union{MultiAlgRSampler, MultiAlgLSampler}, j) = nothing
function update_order!(s::Union{MultiOrdAlgRSampler, MultiOrdAlgLSampler}, j)
    s.ord[j] = nobs(s)
end

update_order_single!(s::MultiAlgRSWRSKIPSampler, r) = nothing
function update_order_single!(s::MultiOrdAlgRSWRSKIPSampler, r)
    s.ord[r] = nobs(s)
end

update_order_multi!(s::MultiAlgRSWRSKIPSampler, r, j) = nothing
function update_order_multi!(s::MultiOrdAlgRSWRSKIPSampler, r, j)
    s.ord[r], s.ord[j] = s.ord[j], nobs(s)
end

is_ordered(s::MultiOrdAlgRSWRSKIPSampler) = true
is_ordered(s::MultiAlgRSWRSKIPSampler) = false

function Base.merge(ss::MultiAlgRSampler...)
    error("To Be Implemented")
end
function Base.merge(ss::MultiAlgLSampler...)
    error("To Be Implemented")
end
function Base.merge(ss::MultiAlgRSWRSKIPSampler...)
    newvalue = reduce_samples(TypeUnion(), ss...)
    skip_k = sum(getfield(s, :skip_k) for s in ss)
    seen_k = sum(getfield(s, :seen_k) for s in ss)
    n = minimum(s.n for s in ss)
    return MultiAlgRSWRSKIPSampler_Mut(n, skip_k, seen_k, ss[1].rng, newvalue, nothing)
end

function Base.merge!(ss::MultiAlgRSampler...)
    error("To Be Implemented")
end
function Base.merge!(ss::MultiAlgLSampler...)
    error("To Be Implemented")
end
function Base.merge!(s1::MultiAlgRSWRSKIPSampler{<:Nothing}, ss::MultiAlgRSWRSKIPSampler...)
    s1.n > minimum(s.n for s in ss) && error("The size of the mutated reservoir should be the minimum size between all merged reservoir")
    newvalue = reduce_samples(TypeS(), s1, ss...)
    for i in 1:length(newvalue)
        @inbounds s1.value[i] = newvalue[i]
    end
    s1.skip_k += sum(getfield(s, :skip_k) for s in ss)
    s1.seen_k += sum(getfield(s, :seen_k) for s in ss)
    return s1
end

function OnlineStatsBase.value(s::Union{MultiAlgRSampler, MultiAlgLSampler})
    if nobs(s) < length(s.value)
        return s.value[1:nobs(s)]
    else
        return s.value
    end
end
function OnlineStatsBase.value(s::MultiAlgRSWRSKIPSampler)
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

function ordvalue(s::Union{MultiOrdAlgRSampler, MultiOrdAlgLSampler})
    if nobs(s) < length(s.value)
        return s.value[1:nobs(s)]
    else
        return s.value[sortperm(s.ord)]
    end
end
function ordvalue(s::MultiOrdAlgRSWRSKIPSampler)
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

