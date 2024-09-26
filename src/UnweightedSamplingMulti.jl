
mutable struct SampleMultiAlgR{O,T,R} <: AbstractWorReservoirSampleMulti
    seen_k::Int
    const rng::R
    const value::Vector{T}
    const ord::O
end
const SampleMultiOrdAlgR = SampleMultiAlgR{<:Vector}

mutable struct SampleMultiAlgL{O,T,R} <: AbstractWorReservoirSampleMulti
    state::Float64
    skip_k::Int
    seen_k::Int
    const rng::R
    const value::Vector{T}
    const ord::O
end
const SampleMultiOrdAlgL = SampleMultiAlgL{<:Vector}

mutable struct SampleMultiAlgRSWRSKIP{O,T,R} <: AbstractWrReservoirSampleMulti
    skip_k::Int
    seen_k::Int
    const rng::R
    const value::Vector{T}
    const ord::O
end
const SampleMultiOrdAlgRSWRSKIP = SampleMultiAlgRSWRSKIP{<:Vector}

function ReservoirSample(T, n::Integer, method::ReservoirAlgorithm=algL; 
        ordered = false)
    return ReservoirSample(Random.default_rng(), T, n, method, ms; ordered = ordered)
end
function ReservoirSample(rng::AbstractRNG, T, n::Integer, method::ReservoirAlgorithm=algL; 
        ordered = false)
    return ReservoirSample(rng, T, n, method, ms; ordered = ordered)
end
function ReservoirSample(rng::AbstractRNG, T, n::Integer, ::AlgL, ::MutSample; 
        ordered = false)
    value = Vector{T}(undef, n)
    if ordered
        return SampleMultiAlgL(0.0, 0, 0, rng, value, collect(1:n))
    else
        return SampleMultiAlgL(0.0, 0, 0, rng, value, nothing)
    end
end
function ReservoirSample(rng::AbstractRNG, T, n::Integer, ::AlgR, ::MutSample; 
        ordered = false)
    value = Vector{T}(undef, n)
    if ordered
        return SampleMultiAlgR(0, rng, value, collect(1:n))
    else
        return SampleMultiAlgR(0, rng, value, nothing)
    end
end
function ReservoirSample(rng::AbstractRNG, T, n::Integer, ::AlgRSWRSKIP, ::MutSample; 
        ordered = false)
    value = Vector{T}(undef, n)
    if ordered
        return SampleMultiAlgRSWRSKIP(0, 0, rng, value, collect(1:n))
    else
        return SampleMultiAlgRSWRSKIP(0, 0, rng, value, nothing)
    end
end

@inline function update!(s::Union{SampleMultiAlgR, SampleMultiOrdAlgR}, el)
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
@inline function update!(s::Union{SampleMultiAlgL, SampleMultiOrdAlgL}, el)
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
@inline function update!(s::AbstractWrReservoirSampleMulti, el)
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

function Base.empty!(s::Union{SampleMultiAlgR, SampleMultiOrdAlgR})
    s.seen_k = 0
    return s
end
function Base.empty!(s::Union{SampleMultiAlgL, SampleMultiOrdAlgL})
    s.state = 0.0
    s.skip_k = 0
    s.seen_k = 0
    return s
end
function Base.empty!(s::Union{SampleMultiAlgRSWRSKIP, SampleMultiOrdAlgRSWRSKIP})
    s.skip_k = 0
    s.seen_k = 0
    return s
end

function update_state!(s::Union{SampleMultiAlgR, SampleMultiOrdAlgR})
    s.seen_k += 1
    return s
end
function update_state!(s::Union{SampleMultiAlgL, SampleMultiOrdAlgL})
    s.seen_k += 1
    s.skip_k -= 1
    return s
end
function update_state!(s::AbstractWrReservoirSampleMulti)
    s.seen_k += 1
    s.skip_k -= 1
    return s
end

function recompute_skip!(s::AbstractWorReservoirSampleMulti, n)
    s.state += randexp(s.rng)
    s.skip_k = -ceil(Int, randexp(s.rng)/log(1-exp(-s.state/n)))
    return s
end
function recompute_skip!(s::AbstractWrReservoirSampleMulti, n)
    q = rand(s.rng)^(1/n)
    s.skip_k = ceil(Int, s.seen_k/q - s.seen_k - 1)
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
    s_merged = SampleMultiAlgRSWRSKIP(0, n_tot, s1.rng, value, nothing)
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

function value(s::AbstractWorReservoirSampleMulti)
    if nobs(s) < length(s.value)
        return s.value[1:nobs(s)]
    else
        return s.value
    end
end
function value(s::AbstractWrReservoirSampleMulti)
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

function itsample(iter, n::Int, method::ReservoirAlgorithm = algL; 
        iter_type = infer_eltype(iter), ordered = false)
    return itsample(Random.default_rng(), iter, n, method; ordered)
end
function itsample(rng::AbstractRNG, iter, n::Int, method::ReservoirAlgorithm = algL;
        iter_type = infer_eltype(iter), ordered = false)
    if Base.IteratorSize(iter) isa Base.SizeUnknown
        reservoir_sample(rng, iter, n, method; iter_type, ordered)::Vector{iter_type}
    else
        replace = method isa AlgL || method isa AlgR ? false : true
        sortedindices_sample(rng, iter, n; iter_type, replace, ordered)::Vector{iter_type}
    end
end

function reservoir_sample(rng, iter, n::Int, method::ReservoirAlgorithm = algL;
        iter_type = infer_eltype(iter), ordered = false)
    s = ReservoirSample(rng, iter_type, n, method, ms; ordered = ordered)
    return update_all!(s, iter, ordered)
end

function update_all!(s, iter, ordered)
    for x in iter
        s = update!(s, x)
    end
    return ordered ? ordered_value(s) : shuffle!(s.rng, value(s))
end

function infer_eltype(itr)
    T1, T2 = eltype(itr), Base.@default_eltype(itr)
    ifelse(T2 !== Union{} && T2 <: T1, T2, T1)
end
