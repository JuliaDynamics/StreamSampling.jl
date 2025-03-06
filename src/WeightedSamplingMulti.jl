
const OrdWeighted = BinaryHeap{Tuple{T, Int64, Float64}, Base.Order.By{typeof(last), DataStructures.FasterForward}} where T

@hybrid struct SampleMultiAlgARes{BH,R} <: AbstractReservoirSample
    seen_k::Int
    n::Int
    const rng::R
    value::BH
end
const SampleMultiOrdAlgARes = Union{SampleMultiAlgARes_Immut{<:OrdWeighted}, SampleMultiAlgARes_Mut{<:OrdWeighted}}

@hybrid struct SampleMultiAlgAExpJ{BH,R} <: AbstractReservoirSample
    state::Float64
    min_priority::Float64
    seen_k::Int
    const n::Int
    const rng::R
    value::BH
end
const SampleMultiOrdAlgAExpJ = Union{SampleMultiAlgAExpJ_Immut{<:OrdWeighted}, SampleMultiAlgAExpJ_Mut{<:OrdWeighted}}

@hybrid struct SampleMultiAlgWRSWRSKIP{O,T,R} <: AbstractReservoirSample
    const n::Int
    state::Float64
    skip_w::Float64
    seen_k::Int
    const rng::R
    const weights::Vector{Float64}
    const value::Vector{T}
    const ord::O
end
const SampleMultiOrdAlgWRSWRSKIP = Union{SampleMultiAlgWRSWRSKIP_Immut{<:Vector}, SampleMultiAlgWRSWRSKIP_Mut{<:Vector}}

function ReservoirSample{T}(rng::AbstractRNG, n::Integer, ::AlgAExpJ, ::MutSample, ::Ord) where T
    value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), Tuple{T, Int, Float64}[])
    sizehint!(value, n)
    return SampleMultiAlgAExpJ_Mut(0.0, 0.0, 0, n, rng, value)
end
function ReservoirSample{T}(rng::AbstractRNG, n::Integer, ::AlgAExpJ, ::MutSample, ::Unord) where T
    value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), Pair{T, Float64}[])
    sizehint!(value, n)
    return SampleMultiAlgAExpJ_Mut(0.0, 0.0, 0, n, rng, value)
end
function ReservoirSample{T}(rng::AbstractRNG, n::Integer, ::AlgAExpJ, ::ImmutSample, ::Ord) where T
    value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), Tuple{T, Int, Float64}[])
    sizehint!(value, n)
    return SampleMultiAlgAExpJ_Immut(0.0, 0.0, 0, n, rng, value)
end
function ReservoirSample{T}(rng::AbstractRNG, n::Integer, ::AlgAExpJ, ::ImmutSample, ::Unord) where T
    value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), Pair{T, Float64}[])
    sizehint!(value, n)
    return SampleMultiAlgAExpJ_Immut(0.0, 0.0, 0, n, rng, value)
end
function ReservoirSample{T}(rng::AbstractRNG, n::Integer, ::AlgARes, ::MutSample, ::Ord) where T
    value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), Tuple{T, Int, Float64}[])
    sizehint!(value, n)
    return SampleMultiAlgARes_Mut(0, n, rng, value)
end
function ReservoirSample{T}(rng::AbstractRNG, n::Integer, ::AlgARes, ::MutSample, ::Unord) where T 
    value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), Pair{T, Float64}[])
    sizehint!(value, n)
    return SampleMultiAlgARes_Mut(0, n, rng, value)
end
function ReservoirSample{T}(rng::AbstractRNG, n::Integer, ::AlgARes, ::ImmutSample, ::Ord) where T
    value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), Tuple{T, Int, Float64}[])
    sizehint!(value, n)
    return SampleMultiAlgARes_Immut(0, n, rng, value)
end
function ReservoirSample{T}(rng::AbstractRNG, n::Integer, ::AlgARes, ::ImmutSample, ::Unord) where T
    value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), Pair{T, Float64}[])
    sizehint!(value, n)
    return SampleMultiAlgARes_Immut(0, n, rng, value)
end
function ReservoirSample{T}(rng::AbstractRNG, n::Integer, ::AlgWRSWRSKIP, ::MutSample, ::Ord) where T
    ord = collect(1:n)
    return SampleMultiAlgWRSWRSKIP_Mut(n, 0.0, 0.0, 0, rng, Vector{Float64}(undef, n), Vector{T}(undef, n), ord)
end
function ReservoirSample{T}(rng::AbstractRNG, n::Integer, ::AlgWRSWRSKIP, ::MutSample, ::Unord) where T
    return SampleMultiAlgWRSWRSKIP_Mut(n, 0.0, 0.0, 0, rng, Vector{Float64}(undef, n), Vector{T}(undef, n), nothing)
end
function ReservoirSample{T}(rng::AbstractRNG, n::Integer, ::AlgWRSWRSKIP, ::ImmutSample, ::Ord) where T
    ord = collect(1:n)
    return SampleMultiAlgWRSWRSKIP_Immut(n, 0.0, 0.0, 0, rng, Vector{Float64}(undef, n), Vector{T}(undef, n), ord)
end
function ReservoirSample{T}(rng::AbstractRNG, n::Integer, ::AlgWRSWRSKIP, ::ImmutSample, ::Unord) where T
    return SampleMultiAlgWRSWRSKIP_Immut(n, 0.0, 0.0, 0, rng, Vector{Float64}(undef, n), Vector{T}(undef, n), nothing)
end

@inline function OnlineStatsBase._fit!(s::Union{SampleMultiAlgARes, SampleMultiOrdAlgARes}, el, w)
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
@inline function OnlineStatsBase._fit!(s::SampleMultiAlgAExpJ, el, w)
    n = s.n
    s = @inline update_state!(s, w)
    if s.seen_k <= n
        priority = exp(-randexp(s.rng)/w)
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
@inline function OnlineStatsBase._fit!(s::SampleMultiAlgWRSWRSKIP, el, w)
    n = s.n
    s = @inline update_state!(s, w)
    if s.seen_k <= n
        @inbounds s.value[s.seen_k] = el
        @inbounds s.weights[s.seen_k] = w
        if s.seen_k == n
            new_values = sample(s.rng, s.value, Weights(s.weights, s.state), n; 
                                ordered = is_ordered(s))
            @inbounds for i in 1:n
                s.value[i] = new_values[i]
            end
            s = @inline recompute_skip!(s, n)
            empty!(s.weights)
        end
        return s
    end
    if s.skip_w <= s.state
        p = w/s.state
        k = @inline choose(s.rng, n, p)
        @inbounds for j in 1:k
            r = rand(s.rng, j:n)
            s.value[r], s.value[j] = s.value[j], el
            update_order_multi!(s, r, j)
        end
        s = @inline recompute_skip!(s, n)
    end
    return s
end

function Base.empty!(s::SampleMultiAlgARes_Mut)
    s.seen_k = 0
    if s isa SampleMultiAlgWRSWRSKIP_Mut{<:Vector}
        s.value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), extract_T(s.value)[])
    else
        s.value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), extract_T(s.value)[])
    end
    sizehint!(s.value, s.n)
    return s
end
function Base.empty!(s::SampleMultiAlgAExpJ_Mut)
    s.state = 0.0
    s.min_priority = 0.0
    s.seen_k = 0
    if s isa SampleMultiAlgWRSWRSKIP_Mut{<:Vector}
        s.value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), extract_T(s.value)[])
    else
        s.value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), extract_T(s.value)[])
    end
    sizehint!(s.value, s.n)
    return s
end
function Base.empty!(s::SampleMultiAlgWRSWRSKIP_Mut)
    s.state = 0.0
    s.skip_w = 0.0
    s.seen_k = 0
    return s
end

extract_T(::DataStructures.BinaryHeap{T}) where T = T

function Base.merge(ss::SampleMultiAlgWRSWRSKIP...)
    newvalue = reduce_samples(TypeUnion(), ss...)
    skip_w = sum(getfield(s, :skip_w) for s in ss)
    state = sum(getfield(s, :state) for s in ss)
    seen_k = sum(getfield(s, :seen_k) for s in ss)
    s = SampleMultiAlgWRSWRSKIP_Mut(ss[1].n, state, skip_w, seen_k, ss[1].rng, Float64[], newvalue, nothing)
    return s
end

function Base.merge!(s1::SampleMultiAlgWRSWRSKIP{<:Nothing}, ss::SampleMultiAlgWRSWRSKIP...)
    newvalue = reduce_samples(TypeS(), s1, ss...)
    for i in 1:length(newvalue)
        @inbounds s1.value[i] = newvalue[i]
    end
    s1.skip_w += sum(getfield(s, :skip_w) for s in ss)
    s1.state += sum(getfield(s, :state) for s in ss)
    s1.seen_k += sum(getfield(s, :seen_k) for s in ss)
    empty!(s1.weights)
    return s1
end

function update_state!(s::SampleMultiAlgARes, w)
    @update s.seen_k += 1
    return s
end
function update_state!(s::SampleMultiAlgAExpJ, w)
    @update s.seen_k += 1
    @update s.state -= w
    return s
end
function update_state!(s::SampleMultiAlgWRSWRSKIP, w)
    @update s.seen_k += 1
    @update s.state += w
    return s
end

function compute_skip_priority(s, w)
    t = exp(log(s.min_priority)*w)
    return exp(log(rand(s.rng, Uniform(t,1)))/w)
end

function recompute_skip!(s::SampleMultiAlgAExpJ)
    @update s.min_priority = last(first(s.value))
    @update s.state = -randexp(s.rng)/log(s.min_priority)
    return s
end
function recompute_skip!(s::SampleMultiAlgWRSWRSKIP, n)
    q = exp(-randexp(s.rng)/n)
    @update s.skip_w = s.state/q
    return s
end

function push_value!(s::Union{SampleMultiAlgARes, SampleMultiAlgAExpJ}, el, priority)
    push!(s.value, el => priority)
end
function push_value!(s::Union{SampleMultiOrdAlgARes, SampleMultiOrdAlgAExpJ}, el, priority)
    push!(s.value, (el, s.seen_k, priority))
end
update_order_single!(s::SampleMultiAlgWRSWRSKIP, r) = nothing
function update_order_single!(s::SampleMultiOrdAlgWRSWRSKIP, r)
    s.ord[r] = nobs(s)
end

update_order_multi!(s::SampleMultiAlgWRSWRSKIP, r, j) = nothing
function update_order_multi!(s::SampleMultiOrdAlgWRSWRSKIP, r, j)
    s.ord[r], s.ord[j] = s.ord[j], nobs(s)
end

is_ordered(s::SampleMultiOrdAlgWRSWRSKIP) = true
is_ordered(s::SampleMultiAlgWRSWRSKIP) = false

function OnlineStatsBase.value(s::Union{SampleMultiAlgARes, SampleMultiAlgAExpJ})
    if nobs(s) < s.n
        return first.(s.value.valtree[1:nobs(s)])
    else
        return first.(s.value.valtree)
    end
end
function OnlineStatsBase.value(s::SampleMultiAlgWRSWRSKIP)
    if nobs(s) < length(s.value)
        return nobs(s) == 0 ? s.value[1:0] : sample(s.rng, s.value[1:nobs(s)], weights(s.weights[1:nobs(s)]), length(s.value))
    else
        return s.value
    end
end

function ordvalue(s::Union{SampleMultiOrdAlgARes, SampleMultiOrdAlgAExpJ})
    if nobs(s) < length(s.value)
        vals = s.value.valtree[1:nobs(s)]
    else
        vals = s.value.valtree    
    end
    return first.(vals[sortperm(map(x -> x[2], vals))])
end
function ordvalue(s::SampleMultiOrdAlgWRSWRSKIP)
    if nobs(s) < length(s.value)
        return sample(s.rng, s.value[1:nobs(s)], weights(s.weights[1:nobs(s)]), length(s.value); ordered=true)
    else
        return s.value[sortperm(s.ord)]
    end
end
