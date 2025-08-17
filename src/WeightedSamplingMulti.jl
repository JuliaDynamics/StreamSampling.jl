
const OrdWeighted = BinaryHeap{Tuple{T, Int64, Float64}, Base.Order.By{typeof(last), DataStructures.FasterForward}} where T

@hybrid struct MultiAlgAResSampler{BH,R} <: AbstractWeightedReservoirSampler
    seen_k::Int
    n::Int
    const rng::R
    value::BH
end
const MultiOrdAlgAResSampler = Union{MultiAlgAResSampler_Immut{<:OrdWeighted}, MultiAlgAResSampler_Mut{<:OrdWeighted}}

@hybrid struct MultiAlgAExpJSampler{BH,R,F} <: AbstractWeightedReservoirSampler
    state::F
    min_priority::F
    seen_k::Int
    const n::Int
    const rng::R
    value::BH
end
const MultiOrdAlgAExpJSampler = Union{MultiAlgAExpJSampler_Immut{<:OrdWeighted}, MultiAlgAExpJSampler_Mut{<:OrdWeighted}}

@hybrid struct MultiAlgWRSWRSKIPSampler{O,T,R,F} <: AbstractWeightedReservoirSampler
    const n::Int
    state::F
    skip_w::F
    seen_k::Int
    const rng::R
    const weights::Memory{F}
    const value::Vector{T}
    const ord::O
end
const MultiOrdAlgWRSWRSKIPSampler = Union{MultiAlgWRSWRSKIPSampler_Immut{<:Memory}, MultiAlgWRSWRSKIPSampler_Mut{<:Memory}}

function ReservoirSampler{T,F}(rng::AbstractRNG, n::Integer, ::AlgAExpJ, ::MutSampler, ::Ord) where {T,F}
    value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), Tuple{T, Int, F}[])
    sizehint!(value, n)
    return MultiAlgAExpJSampler_Mut(zero(F), zero(F), 0, n, rng, value)
end
function ReservoirSampler{T,F}(rng::AbstractRNG, n::Integer, ::AlgAExpJ, ::MutSampler, ::Unord) where {T,F}
    value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), Pair{T, F}[])
    sizehint!(value, n)
    return MultiAlgAExpJSampler_Mut(zero(F), zero(F), 0, n, rng, value)
end
function ReservoirSampler{T,F}(rng::AbstractRNG, n::Integer, ::AlgAExpJ, ::ImmutSampler, ::Ord) where {T,F}
    value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), Tuple{T, Int, F}[])
    sizehint!(value, n)
    return MultiAlgAExpJSampler_Immut(zero(F), zero(F), 0, n, rng, value)
end
function ReservoirSampler{T,F}(rng::AbstractRNG, n::Integer, ::AlgAExpJ, ::ImmutSampler, ::Unord) where {T,F}
    value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), Pair{T, F}[])
    sizehint!(value, n)
    return MultiAlgAExpJSampler_Immut(zero(F), zero(F), 0, n, rng, value)
end
function ReservoirSampler{T,F}(rng::AbstractRNG, n::Integer, ::AlgARes, ::MutSampler, ::Ord) where {T,F}
    value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), Tuple{T, Int, F}[])
    sizehint!(value, n)
    return MultiAlgAResSampler_Mut(0, n, rng, value)
end
function ReservoirSampler{T,F}(rng::AbstractRNG, n::Integer, ::AlgARes, ::MutSampler, ::Unord) where {T,F}
    value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), Pair{T, F}[])
    sizehint!(value, n)
    return MultiAlgAResSampler_Mut(0, n, rng, value)
end
function ReservoirSampler{T,F}(rng::AbstractRNG, n::Integer, ::AlgARes, ::ImmutSampler, ::Ord) where {T,F}
    value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), Tuple{T, Int, F}[])
    sizehint!(value, n)
    return MultiAlgAResSampler_Immut(0, n, rng, value)
end
function ReservoirSampler{T,F}(rng::AbstractRNG, n::Integer, ::AlgARes, ::ImmutSampler, ::Unord) where {T,F}
    value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), Pair{T, F}[])
    sizehint!(value, n)
    return MultiAlgAResSampler_Immut(0, n, rng, value)
end
function ReservoirSampler{T,F}(rng::AbstractRNG, n::Integer, ::AlgWRSWRSKIP, ::MutSampler, ::Ord) where {T,F}
    ord = ordmemory(n)
    return MultiAlgWRSWRSKIPSampler_Mut(n, zero(F), zero(F), 0, rng, Memory{F}(undef, n), Vector{T}(undef, n), ord)
end
function ReservoirSampler{T,F}(rng::AbstractRNG, n::Integer, ::AlgWRSWRSKIP, ::MutSampler, ::Unord) where {T,F}
    return MultiAlgWRSWRSKIPSampler_Mut(n, zero(F), zero(F), 0, rng, Memory{F}(undef, n), Vector{T}(undef, n), nothing)
end
function ReservoirSampler{T,F}(rng::AbstractRNG, n::Integer, ::AlgWRSWRSKIP, ::ImmutSampler, ::Ord) where {T,F}
    ord = ordmemory(n)
    return MultiAlgWRSWRSKIPSampler_Immut(n, zero(F), zero(F), 0, rng, Memory{F}(undef, n), Vector{T}(undef, n), ord)
end
function ReservoirSampler{T,F}(rng::AbstractRNG, n::Integer, ::AlgWRSWRSKIP, ::ImmutSampler, ::Unord) where {T,F}
    return MultiAlgWRSWRSKIPSampler_Immut(n, zero(F), zero(F), 0, rng, Memory{F}(undef, n), Vector{T}(undef, n), nothing)
end

@inline function OnlineStatsBase._fit!(s::Union{MultiAlgAResSampler, MultiOrdAlgAResSampler}, el, w)
    w < 0.0 && error(lazy"Passed element $(el) with weight $(w), but weights must be positive.")
    n = s.n
    s = @inline update_state!(s, w)
    priority = -randexp(s.rng)/w
    if s.seen_k <= n
        @inline push_value!(s, el, priority)
        return s
    end
    min_priority = last(first(s.value))
    if priority > min_priority
        pop!(s.value)
        @inline push_value!(s, el, priority)
    end
    return s
end
@inline function OnlineStatsBase._fit!(s::MultiAlgAExpJSampler, el, w)
    w < 0.0 && error(lazy"Passed element $(el) with weight $(w), but weights must be positive.")
    n = s.n
    s = @inline update_state!(s, w)
    if s.seen_k <= n
        priority = -randexp(s.rng)/w
        @inline push_value!(s, el, priority)
        if s.seen_k == n 
            s = @inline recompute_skip!(s)
        end
        return s
    end
    if s.state <= 0.0
        priority = @inline compute_skip_priority(s, w)
        pop!(s.value)
        @inline push_value!(s, el, priority)
        s = @inline recompute_skip!(s)
    end
    return s
end
@inline function OnlineStatsBase._fit!(s::MultiAlgWRSWRSKIPSampler, el, w)
    w < 0.0 && error(lazy"Passed element $(el) with weight $(w), but weights must be positive.")
    n = s.n
    s = @inline update_state!(s, w)
    if s.seen_k <= n
        @inbounds s.value[s.seen_k] = el
        @inbounds s.weights[s.seen_k] = w
        if s.seen_k == n
            randexps = randexp(s.rng, n)
            ratio = s.state/(sum(randexps) + randexp(s.rng))
            j, csweights, limit = 1, first(s.weights), 0.0
            for i in eachindex(s.value, s.weights, randexps)
                limit += randexps[i] * ratio
                while csweights < limit
                    j += 1
                    csweights += s.weights[j]
                end
                s.value[i] = j
            end
            s = @inline recompute_skip!(s, n)
        end
        return s
    end
    if s.skip_w <= s.state
        p = w/s.state
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

function Base.empty!(s::MultiAlgAResSampler_Mut)
    s.seen_k = 0
    if s isa MultiAlgWRSWRSKIPSampler_Mut{<:Vector}
        s.value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), extract_T(s.value)[])
    else
        s.value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), extract_T(s.value)[])
    end
    sizehint!(s.value, s.n)
    return s
end
function Base.empty!(s::MultiAlgAExpJSampler_Mut)
    s.state = 0.0
    s.min_priority = 0.0
    s.seen_k = 0
    if s isa MultiAlgWRSWRSKIPSampler_Mut{<:Vector}
        s.value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), extract_T(s.value)[])
    else
        s.value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), extract_T(s.value)[])
    end
    sizehint!(s.value, s.n)
    return s
end
function Base.empty!(s::MultiAlgWRSWRSKIPSampler_Mut)
    s.state = 0.0
    s.skip_w = 0.0
    s.seen_k = 0
    return s
end

extract_T(::DataStructures.BinaryHeap{T}) where T = T

function Base.merge(ss::MultiAlgAResSampler...)
    newvalue = reduce_samples(TypeUnion(), ss...)
    newheap = BinaryHeap(Base.By(last, DataStructures.FasterForward()), newvalue)
    seen_k = sum(getfield(s, :seen_k) for s in ss)
    n = minimum(s.n for s in ss)
    s = MultiAlgAResSampler_Mut(seen_k, n, ss[1].rng, newheap)
    return s
end
function Base.merge(ss::MultiAlgAExpJSampler...)
    newvalue = reduce_samples(TypeUnion(), ss...)
    newheap = BinaryHeap(Base.By(last, DataStructures.FasterForward()), newvalue)
    seen_k = sum(getfield(s, :seen_k) for s in ss)
    state = sum(getfield(s, :state) for s in ss)
    min_priority = minimum(getfield(s, :min_priority) for s in ss)
    n = minimum(s.n for s in ss)
    s = MultiAlgAExpJSampler_Mut(state, min_priority, seen_k, n, ss[1].rng, newheap)
    return s
end
function Base.merge(ss::MultiAlgWRSWRSKIPSampler...)
    newvalue = reduce_samples(TypeUnion(), ss...)
    skip_w = sum(getfield(s, :skip_w) for s in ss)
    state = sum(getfield(s, :state) for s in ss)
    seen_k = sum(getfield(s, :seen_k) for s in ss)
    n = minimum(s.n for s in ss)
    s = MultiAlgWRSWRSKIPSampler_Mut(n, state, skip_w, seen_k, ss[1].rng, Memory{Float64}(undef,0), newvalue, nothing)
    return s
end

function Base.merge!(s1::MultiAlgAResSampler, ss::MultiAlgAResSampler...)
    length(typeof(s1.value.valtree).parameters) == 3 && error("Merging ordered reservoirs is not possible")
    s1.n > minimum(s.n for s in ss) && error("The size of the mutated reservoir should be the minimum size between all merged reservoir")
    empty!(s1.value.valtree)
    newvalue = reduce_samples(TypeS(), s1, ss...)
    for e in newvalue
        push!(s1.value, e[1] => e[2])
    end
    s1.seen_k += sum(getfield(s, :seen_k) for s in ss)
    return s1
end
function Base.merge!(s1::MultiAlgAExpJSampler, ss::MultiAlgAExpJSampler...)
    length(typeof(s1.value.valtree).parameters) == 3 && error("Merging ordered reservoirs is not possible")
    s1.n > minimum(s.n for s in ss) && error("The size of the mutated reservoir should be the minimum size between all merged reservoir")
    empty!(s1.value.valtree)
    newvalue = reduce_samples(TypeS(), s1, ss...)
    for e in newvalue
        push!(s1.value, e[1] => e[2])
    end
    s1.seen_k += sum(getfield(s, :seen_k) for s in ss)
    s1.state += sum(getfield(s, :state) for s in ss)
    s1.min_priority = min(s1.min_priority, minimum(getfield(s, :min_priority) for s in ss))
    return s1
end
function Base.merge!(s1::MultiAlgWRSWRSKIPSampler{<:Nothing}, ss::MultiAlgWRSWRSKIPSampler...)
    s1.n > minimum(s.n for s in ss) && error("The size of the mutated reservoir should be the minimum size between all merged reservoir")
    newvalue = reduce_samples(TypeS(), s1, ss...)
    for i in 1:length(newvalue)
        @inbounds s1.value[i] = newvalue[i]
    end
    s1.skip_w += sum(getfield(s, :skip_w) for s in ss)
    s1.state += sum(getfield(s, :state) for s in ss)
    s1.seen_k += sum(getfield(s, :seen_k) for s in ss)
    return s1
end

function update_state!(s::MultiAlgAResSampler, w)
    @update s.seen_k += 1
    return s
end
function update_state!(s::MultiAlgAExpJSampler, w)
    @update s.seen_k += 1
    @update s.state -= w
    return s
end
function update_state!(s::MultiAlgWRSWRSKIPSampler, w)
    @update s.seen_k += 1
    @update s.state += w
    return s
end

function compute_skip_priority(s, w)
    t = exp(s.min_priority*w)
    return log(rand(s.rng, Uniform(t,1)))/w
end

function recompute_skip!(s::MultiAlgAExpJSampler)
    @update s.min_priority = last(first(s.value))
    @update s.state = -randexp(s.rng)/s.min_priority
    return s
end
function recompute_skip!(s::MultiAlgWRSWRSKIPSampler, n)
    q = exp(randexp(s.rng)/n)
    @update s.skip_w = s.state*q
    return s
end

function push_value!(s::Union{MultiAlgAResSampler, MultiAlgAExpJSampler}, el, priority)
    push!(s.value, el => priority)
end
function push_value!(s::Union{MultiOrdAlgAResSampler, MultiOrdAlgAExpJSampler}, el, priority)
    push!(s.value, (el, s.seen_k, priority))
end
update_order_single!(s::MultiAlgWRSWRSKIPSampler, r) = nothing
function update_order_single!(s::MultiOrdAlgWRSWRSKIPSampler, r)
    s.ord[r] = nobs(s)
end

update_order_multi!(s::MultiAlgWRSWRSKIPSampler, r, j) = nothing
function update_order_multi!(s::MultiOrdAlgWRSWRSKIPSampler, r, j)
    s.ord[r], s.ord[j] = s.ord[j], nobs(s)
end

is_ordered(s::MultiOrdAlgWRSWRSKIPSampler) = true
is_ordered(s::MultiAlgWRSWRSKIPSampler) = false

function OnlineStatsBase.value(s::Union{MultiAlgAResSampler, MultiAlgAExpJSampler})
    if nobs(s) < s.n
        return first.(s.value.valtree[1:nobs(s)])
    else
        return first.(s.value.valtree)
    end
end
function OnlineStatsBase.value(s::MultiAlgWRSWRSKIPSampler)
    if nobs(s) < length(s.value)
        return nobs(s) == 0 ? s.value[1:0] : sample(s.rng, s.value[1:nobs(s)], weights(s.weights[1:nobs(s)]), length(s.value))
    else
        return s.value
    end
end

function ordvalue(s::Union{MultiOrdAlgAResSampler, MultiOrdAlgAExpJSampler})
    if nobs(s) < length(s.value)
        vals = s.value.valtree[1:nobs(s)]
    else
        vals = s.value.valtree    
    end
    return first.(vals[sortperm(map(x -> x[2], vals))])
end
function ordvalue(s::MultiOrdAlgWRSWRSKIPSampler)
    if nobs(s) < length(s.value)
        return sample(s.rng, s.value[1:nobs(s)], weights(s.weights[1:nobs(s)]), length(s.value); ordered=true)
    else
        return s.value[sortperm(s.ord)]
    end
end
