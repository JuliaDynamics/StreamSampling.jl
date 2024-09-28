
@hybrid struct SampleMultiAlgR{O,T,R} <: AbstractWorReservoirSampleMulti
    seen_k::Int
    const rng::R
    const value::Vector{T}
    const ord::O
end
const SampleMultiOrdAlgR = SampleMultiAlgR{<:Vector}

@hybrid struct SampleMultiAlgL{O,T,R} <: AbstractWorReservoirSampleMulti
    state::Float64
    skip_k::Int
    seen_k::Int
    const rng::R
    const value::Vector{T}
    const ord::O
end
const SampleMultiOrdAlgL = SampleMultiAlgL{<:Vector}

@hybrid struct SampleMultiAlgRSWRSKIP{O,T,R} <: AbstractWrReservoirSampleMulti
    skip_k::Int
    seen_k::Int
    const rng::R
    const value::Vector{T}
    const ord::O
end
const SampleMultiOrdAlgRSWRSKIP = SampleMultiAlgRSWRSKIP{<:Vector}

function ReservoirSample(rng::AbstractRNG, T, n::Integer, ::AlgL, ::MutSample, ::Ord)
    return SampleMultiAlgL_Mut(0.0, 0, 0, rng, Vector{T}(undef, n), collect(1:n))
end
function ReservoirSample(rng::AbstractRNG, T, n::Integer, ::AlgL, ::MutSample, ::Unord)
    return SampleMultiAlgL_Mut(0.0, 0, 0, rng, Vector{T}(undef, n), nothing)
end
function ReservoirSample(rng::AbstractRNG, T, n::Integer, ::AlgL, ::ImmutSample, ::Ord)
    return SampleMultiAlgL_Immut(0.0, 0, 0, rng, Vector{T}(undef, n), collect(1:n))
end
function ReservoirSample(rng::AbstractRNG, T, n::Integer, ::AlgL, ::ImmutSample, ::Unord)
    return SampleMultiAlgL_Immut(0.0, 0, 0, rng, Vector{T}(undef, n), nothing)
end
function ReservoirSample(rng::AbstractRNG, T, n::Integer, ::AlgR, ::MutSample, ::Ord) 
    return SampleMultiAlgR_Mut(0, rng, Vector{T}(undef, n), collect(1:n))
end        
function ReservoirSample(rng::AbstractRNG, T, n::Integer, ::AlgR, ::MutSample, ::Unord) 
    return SampleMultiAlgR_Mut(0, rng, Vector{T}(undef, n), nothing)
end
function ReservoirSample(rng::AbstractRNG, T, n::Integer, ::AlgR, ::ImmutSample, ::Ord) 
    return SampleMultiAlgR_Immut(0, rng, Vector{T}(undef, n), collect(1:n))
end
function ReservoirSample(rng::AbstractRNG, T, n::Integer, ::AlgR, ::ImmutSample, ::Unord) 
    return SampleMultiAlgR_Immut(0, rng, Vector{T}(undef, n), nothing)
end
function ReservoirSample(rng::AbstractRNG, T, n::Integer, ::AlgRSWRSKIP, ::MutSample, ::Ord)
    return SampleMultiAlgRSWRSKIP_Mut(0, 0, rng, Vector{T}(undef, n), collect(1:n))
end
function ReservoirSample(rng::AbstractRNG, T, n::Integer, ::AlgRSWRSKIP, ::MutSample, ::Unord)
    return SampleMultiAlgRSWRSKIP_Mut(0, 0, rng, Vector{T}(undef, n), nothing)
end
function ReservoirSample(rng::AbstractRNG, T, n::Integer, ::AlgRSWRSKIP, ::ImmutSample, ::Ord)
    return SampleMultiAlgRSWRSKIP_Immut(0, 0, rng, Vector{T}(undef, n), collect(1:n))
end
function ReservoirSample(rng::AbstractRNG, T, n::Integer, ::AlgRSWRSKIP, ::ImmutSample, ::Unord)
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
    elseif s.skip_k < 0
        j = rand(s.rng, 1:n)
        @inbounds s.value[j] = el
        update_order!(s, j)
        s = @inline recompute_skip!(s, n)
    end
    return s
end
@inline function OnlineStatsBase._fit!(s::AbstractWrReservoirSampleMulti, el)
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
    elseif s.skip_k < 0
        p = 1/s.seen_k
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
    @update s.skip_k -= 1
    return s
end
function update_state!(s::AbstractWrReservoirSampleMulti)
    @update s.seen_k += 1
    @update s.skip_k -= 1
    return s
end

function recompute_skip!(s::AbstractWorReservoirSampleMulti, n)
    @update s.state += randexp(s.rng)
    @update s.skip_k = -ceil(Int, randexp(s.rng)/log(1-exp(-s.state/n)))
    return s
end
function recompute_skip!(s::AbstractWrReservoirSampleMulti, n)
    q = rand(s.rng)^(1/n)
    @update s.skip_k = ceil(Int, s.seen_k/q - s.seen_k - 1)
    return s
end

function choose(n, p, q, z)
    m = 1-p
    s = z
    z = s*m*m*(m + n*p)
    z > q && return 1
    z += n*p*(n-1)*p*s*m/2
    z > q && return 2
    z += n*p*(n-1)*p*(n-2)*p*s/6
    z > q && return 3
    b = Binomial(n, p)
    return quantile(b, q)
end

update_order!(s::AbstractWorReservoirSampleMulti, j) = nothing
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
is_ordered(s::AbstractWrReservoirSampleMulti) = false

function Base.merge(s1::AbstractWrReservoirSampleMulti, s2::AbstractWrReservoirSampleMulti)
    len1, len2, n1, n2 = check_merging_support(s1, s2)
    shuffle!(s1.rng, s1.value)
    shuffle!(s2.rng, s2.value)
    n_tot = n1 + n2
    p = n2 / n_tot
    value = create_new_res_vec(s1, s2, p, len1)
    s_merged = typeof(s1)(0, n_tot, s1.rng, value, nothing)
    recompute_skip!(s_merged, len1)
    return s_merged
end

function Base.merge!(s1::SampleMultiAlgRSWRSKIP, s2::AbstractWrReservoirSampleMulti)
    len1, len2, n1, n2 = check_merging_support(s1, s2)
    shuffle!(s1.rng, s1.value)
    shuffle!(s2.rng, s2.value)
    n_tot = n1 + n2
    p = n2 / n_tot
    merge_res_vec!(s1, s2, p, len1, n_tot)
    recompute_skip!(s1, len1)
    return s1
end

function check_merging_support(s1, s2)
    len1, len2 = length(s1.value), length(s2.value)
    len1 != len2 && error("Merging samples with different sizes is not supported")
    n1, n2 = nobs(s1), nobs(s2)
    n1 < len1 || n2 < len2 && error("Merging samples with different sizes is not supported")
    return len1, len2, n1, n2
end

function create_new_res_vec(s1, s2, p, len1)
    value = similar(s1.value)
    @inbounds for j in 1:len1
        value[j] = rand(s1.rng) < p ? s2.value[j] : s1.value[j]
    end
    return value
end

function merge_res_vec!(s1, s2, p, len1, n_tot)
    @inbounds for j in 1:len1
        if rand(s1.rng) < p
            s1.value[j] = s2.value[j]
        end
    end
    s1.seen_k = n_tot
    return s1
end

function OnlineStatsBase.value(s::AbstractWorReservoirSampleMulti)
    if nobs(s) < length(s.value)
        return s.value[1:nobs(s)]
    else
        return s.value
    end
end
function OnlineStatsBase.value(s::AbstractWrReservoirSampleMulti)
    if nobs(s) < length(s.value)
        return sample(s.rng, s.value[1:nobs(s)], length(s.value))
    else
        return s.value
    end
end

function ordered_value(s::Union{SampleMultiOrdAlgR, SampleMultiOrdAlgL})
    if nobs(s) < length(s.value)
        return s.value[1:nobs(s)]
    else
        return s.value[sortperm(s.ord)]
    end
end
function ordered_value(s::SampleMultiOrdAlgRSWRSKIP)
    if nobs(s) < length(s.value)
        return sample(s.rng, s.value[1:nobs(s)], length(s.value); ordered=true)
    else
        return s.value[sortperm(s.ord)]
    end
end

Base.@constprop :aggressive function reservoir_sample(rng, iter, n::Int, method::ReservoirAlgorithm = algL;
        iter_type = infer_eltype(iter), ordered = false)
    s = ReservoirSample(rng, iter_type, n, method, ims, ordered ? Ord() : Unord())
    return update_all!(s, iter, ordered)
end

function update_all!(s, iter, ordered)
    for x in iter
        s = fit!(s, x)
    end
    return ordered ? ordered_value(s) : shuffle!(s.rng, value(s))
end
