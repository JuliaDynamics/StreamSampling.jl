
@hybrid struct SampleMultiAlgARes{BH,R} <: AbstractWeightedWorReservoirSampleMulti
    seen_k::Int
    n::Int
    const rng::R
    const value::BH
end

@hybrid struct SampleMultiAlgAExpJ{BH,R} <: AbstractWeightedWorReservoirSampleMulti
    state::Float64
    min_priority::Float64
    seen_k::Int
    n::Int
    const rng::R
    const value::BH
end

@hybrid struct SampleMultiAlgWRSWRSKIP{O,V,R} <: AbstractWeightedWrReservoirSampleMulti
    state::Float64
    skip_w::Float64
    seen_k::Int
    const rng::R
    const weights::Vector{Float64}
    const value::V
    const ord::O
end

function ReservoirSample(rng::AbstractRNG, T, n::Integer, ::AlgAExpJ, ::MutSample; 
        ordered = false)
    if ordered
        value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), Tuple{T, Int, Float64}[])
        sizehint!(value, n)
        return SampleMultiOrdAlgAExpJ(0.0, 0.0, 0, n, rng, value; mutable=true)
    else
        value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), Pair{T, Float64}[])
        sizehint!(value, n)
        return SampleMultiAlgAExpJ(0.0, 0.0, 0, n, rng, value; mutable=true)
    end
end
function ReservoirSample(rng::AbstractRNG, T, n::Integer, ::AlgAExpJ, ::ImmutSample; 
        ordered = false)
    if ordered
        value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), Tuple{T, Int, Float64}[])
        sizehint!(value, n)
        return SampleMultiOrdAlgAExpJ(0.0, 0.0, 0, n, rng, value; mutable=false)
    else
        value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), Pair{T, Float64}[])
        sizehint!(value, n)
        return SampleMultiAlgAExpJ(0.0, 0.0, 0, n, rng, value; mutable=false)
    end
end
function ReservoirSample(rng::AbstractRNG, T, n::Integer, ::AlgARes, ::MutSample;  
        ordered = false)
    if ordered
        value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), Tuple{T, Int, Float64}[])
        sizehint!(value, n)
        return MutSampleMultiOrdAlgARes(0, n, rng, value; mutable=true)
    else
        value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), Pair{T, Float64}[])
        sizehint!(value, n)
        return MutSampleMultiAlgARes(0, n, rng, value; mutable=true)
    end
end
function ReservoirSample(rng::AbstractRNG, T, n::Integer, ::AlgARes, ::ImmutSample;  
        ordered = false)
    if ordered
        value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), Tuple{T, Int, Float64}[])
        sizehint!(value, n)
        return SampleMultiOrdAlgARes(0, n, rng, value; mutable=false)
    else
        value = BinaryHeap(Base.By(last, DataStructures.FasterForward()), Pair{T, Float64}[])
        sizehint!(value, n)
        return SampleMultiAlgARes(0, n, rng, value; mutable=false)
    end
end
function ReservoirSample(rng::AbstractRNG, T, n::Integer, method::AlgWRSWRSKIP, ms::MutSample; 
        ordered = false)
    value = Vector{T}(undef, n)
    weights = Vector{Float64}(undef, n)
    if ordered
        ord = collect(1:n)
        return MutSampleMultiOrdAlgWRSWRSKIP(0.0, 0.0, 0, rng, weights, value, ord)
    else
        return MutSampleMultiAlgWRSWRSKIP(0.0, 0.0, 0, rng, weights, value, nothing)
    end
end
function ReservoirSample(rng::AbstractRNG, T, n::Integer, method::AlgWRSWRSKIP, ims::ImmutSample; 
        ordered = false)
    value = Vector{T}(undef, n)
    weights = Vector{Float64}(undef, n)
    if ordered
        ord = collect(1:n)
        return ImmutSampleMultiOrdAlgWRSWRSKIP(0.0, 0.0, 0, rng, weights, value, ord)
    else
        return ImmutSampleMultiAlgWRSWRSKIP(0.0, 0.0, 0, rng, weights, value, nothing)
    end
end

@inline function update!(s::Union{SampleMultiAlgARes_Mut, SampleMultiAlgARes_Immut}, el, w)
    n = s.n
    s = @inline update_state!(s, w)
    priority = -randexp(s.rng)/w
    if s.seen_k <= n
        push_value!(s, el, priority)
    else
        min_priority = last(first(s.value))
        if priority > min_priority
            pop!(s.value)
            push_value!(s, el, priority)
        end
    end
    return s
end
@inline function update!(s::Union{SampleMultiAlgAExpJ_Mut, SampleMultiAlgAExpJ_Immut}, el, w)
    n = s.n
    s = @inline update_state!(s, w)
    if s.seen_k <= n
        priority = exp(-randexp(s.rng)/w)
        push_value!(s, el, priority)
        if s.seen_k == n 
            s = @inline recompute_skip!(s)
        end
    elseif s.state <= 0.0
        priority = @inline compute_skip_priority(s, w)
        pop!(s.value)
        push_value!(s, el, priority)
        s = @inline recompute_skip!(s)
    end
    return s
end
@inline function update!(s::Union{SampleMultiAlgWRSWRSKIP, SampleMultiOrdAlgWRSWRSKIP}, el, w)
    n = length(s.value)
    s = @inline update_state!(s, w)
    if s.seen_k <= n
        @inbounds s.value[s.seen_k] = el
        @inbounds s.weights[s.seen_k] = w
        if s.seen_k == n
            new_values = sample(s.rng, s.value, weights(s.weights), n; ordered = is_ordered(s))
            @inbounds for i in 1:n
                s.value[i] = new_values[i]
            end
            s = @inline recompute_skip!(s, n)
            empty!(s.weights)
        end
    elseif s.skip_w <= s.state
        p = w/s.state
        z = (1-p)^(n-3)
        q = rand(s.rng, Uniform(z*(1-p)*(1-p)*(1-p),1.0))
        k = choose(n, p, q, z)
        @inbounds begin
            if k == 1
                r = rand(s.rng, 1:n)
                s.value[r] = el
                update_order_single!(s, r)
            else
                for j in 1:k
                    r = rand(s.rng, j:n)
                    s.value[r] = el
                    s.value[r], s.value[j] = s.value[j], s.value[r]
                    update_order_multi!(s, r, j)
                end
            end 
        end
        s = @inline recompute_skip!(s, n)
    end
    return s
end

function Base.empty!(s::SampleMultiAlgARes_Mut)
    s.seen_k = 0
    empty!(s.value)
    sizehint!(s.value, s.n)
    return s
end
function Base.empty!(s::SampleMultiAlgAExpJ_Mut)
    s.state = 0.0
    s.min_priority = 0.0
    s.seen_k = 0
    empty!(s.value)
    sizehint!(s.value, s.n)
    return s
end
function Base.empty!(s::Union{MutSampleMultiAlgWRSWRSKIP, MutSampleMultiOrdAlgWRSWRSKIP})
    s.state = 0.0
    s.skip_w = 0.0
    s.seen_k = 0
    return s
end

function update_state!(s::Union{SampleMultiAlgARes_Mut, SampleMultiAlgARes_Immut}, w)
    @update s.seen_k += 1
    return s
end
function update_state!(s::Union{SampleMultiAlgAExpJ_Mut, SampleMultiAlgAExpJ_Immut}, w)
    @update s.seen_k += 1
    @update s.state -= w
    return s
end
function update_state!(s::Union{SampleMultiAlgWRSWRSKIP, SampleMultiOrdAlgWRSWRSKIP}, w)
    @update s.seen_k += 1
    @update s.state += w
    return s
end

function compute_skip_priority(s, w)
    t = exp(log(s.min_priority)*w)
    return exp(log(rand(s.rng, Uniform(t,1)))/w)
end

function recompute_skip!(s::Union{SampleMultiAlgAExpJ_Mut, SampleMultiAlgAExpJ_Immut})
    @update s.min_priority = last(first(s.value))
    @update s.state = -randexp(s.rng)/log(s.min_priority)
    return s
end
function recompute_skip!(s::Union{SampleMultiAlgWRSWRSKIP, SampleMultiOrdAlgWRSWRSKIP}, n)
    q = rand(s.rng)^(1/n)
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

function value(s::AbstractWeightedWorReservoirSampleMulti)
    if nobs(s) < s.n
        return first.(s.value.valtree[1:nobs(s)])
    else
        return first.(s.value.valtree)
    end
end
function value(s::AbstractWeightedWrReservoirSampleMulti)
    if nobs(s) < length(s.value)
        return sample(s.rng, s.value[1:nobs(s)], weights(s.weights[1:nobs(s)]), length(s.value))
    else
        return s.value
    end
end

function ordered_value(s::Union{SampleMultiOrdAlgARes, SampleMultiOrdAlgAExpJ})
    if nobs(s) < length(s.value)
        vals = s.value.valtree[1:nobs(s)]
    else
        vals = s.value.valtree    
    end
    return first.(vals[sortperm(map(x -> x[2], vals))])
end
function ordered_value(s::SampleMultiOrdAlgWRSWRSKIP)
    if nobs(s) < length(s.value)
        return sample(s.rng, s.value[1:nobs(s)], weights(s.weights[1:nobs(s)]), length(s.value); ordered=true)
    else
        return s.value[sortperm(s.ord)]
    end
end

function itsample(iter, wv::Function, n::Int, method::ReservoirAlgorithm=algAExpJ; 
        iter_type = infer_eltype(iter), ordered = false)
    return itsample(Random.default_rng(), iter, wv, n, method; iter_type, ordered)
end

function itsample(rng::AbstractRNG, iter, wv::Function, n::Int, method::ReservoirAlgorithm=algAExpJ; 
        iter_type = infer_eltype(iter), ordered = false)
    return reservoir_sample(rng, iter, wv, n, method; iter_type, ordered)
end

function reservoir_sample(rng, iter, wv::Function, n::Int, method::ReservoirAlgorithm=algAExpJ; 
        iter_type = infer_eltype(iter), ordered = false)
    s = ReservoirSample(rng, iter_type, n, method, ims; ordered = ordered)
    return update_all!(s, iter, wv, ordered)
end

function update_all!(s, iter, wv, ordered)
    for x in iter
        s = update!(s, x, wv(x))
    end
    return ordered ? ordered_value(s) : shuffle!(s.rng, value(s))
end
