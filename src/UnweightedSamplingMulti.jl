
mutable struct SampleMultiAlgR{T,R} <: AbstractWorReservoirSampleMulti
    seen_k::Int
    const rng::R
    const value::Vector{T}
end

mutable struct SampleMultiOrdAlgR{T,R} <: AbstractOrdWorReservoirSampleMulti
    seen_k::Int
    const rng::R
    const value::Vector{T}
    const ord::Vector{Int}
end

mutable struct SampleMultiAlgL{T,R} <: AbstractWorReservoirSampleMulti
    state::Float64
    skip_k::Int
    seen_k::Int
    const rng::R
    const value::Vector{T}
end

mutable struct SampleMultiOrdAlgL{T,R} <: AbstractOrdWorReservoirSampleMulti
    state::Float64
    skip_k::Int
    seen_k::Int
    const rng::R
    const value::Vector{T}
    const ord::Vector{Int}
end

mutable struct SampleMultiAlgRSWRSKIP{T,R} <: AbstractWrReservoirSampleMulti
    skip_k::Int
    seen_k::Int
    const rng::R
    const value::Vector{T}
end

mutable struct SampleMultiOrdAlgRSWRSKIP{T,R} <: AbstractOrdWrReservoirSampleMulti
    skip_k::Int
    seen_k::Int
    const rng::R
    const value::Vector{T}
    const ord::Vector{Int}
end

function ReservoirSample(T, n::Integer, method::ReservoirAlgorithm=algL; ordered = false)
    return ReservoirSample(Random.default_rng(), T, n, method; ordered = ordered)
end
function ReservoirSample(rng::AbstractRNG, T, n::Integer, method::AlgL=algL; ordered = false)
    value = Vector{T}(undef, n)
    if ordered
        return SampleMultiOrdAlgL(0.0, 0, 0, rng, value, collect(1:n))
    else
        return SampleMultiAlgL(0.0, 0, 0, rng, value)
    end
end
function ReservoirSample(rng::AbstractRNG, T, n::Integer, method::AlgR; ordered = false)
    value = Vector{T}(undef, n)
    if ordered
        return SampleMultiOrdAlgR(0, rng, value, collect(1:n))
    else
        return SampleMultiAlgR(0, rng, value)
    end
end
function ReservoirSample(rng::AbstractRNG, T, n::Integer, method::AlgRSWRSKIP; ordered = false)
    value = Vector{T}(undef, n)
    if ordered
        return SampleMultiOrdAlgRSWRSKIP(0, 0, rng, value, collect(1:n))
    else
        return SampleMultiAlgRSWRSKIP(0, 0, rng, value)
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
        if s.seen_k == n
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
        if s.seen_k == n
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

function update_state!(s::Union{SampleMultiAlgR, SampleMultiOrdAlgR})
    @imm_reset s.seen_k += 1
    return s
end
function update_state!(s::Union{SampleMultiAlgL, SampleMultiOrdAlgL})
    @imm_reset s.seen_k += 1
    @imm_reset s.skip_k -= 1
    return s
end
function update_state!(s::AbstractWrReservoirSampleMulti)
    @imm_reset s.seen_k += 1
    @imm_reset s.skip_k -= 1
    return s
end

function recompute_skip!(s::AbstractWorReservoirSampleMulti, n)
    @imm_reset s.state += randexp(s.rng)
    @imm_reset s.skip_k = -ceil(Int, randexp(s.rng)/log(1-exp(-s.state/n)))
    return s
end
function recompute_skip!(s::AbstractWrReservoirSampleMulti, n)
    q = rand(s.rng)^(1/n)
    @imm_reset s.skip_k = ceil(Int, s.seen_k/q - s.seen_k - 1)
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
function update_order!(s::AbstractOrdWorReservoirSampleMulti, j)
    s.ord[j] = n_seen(s)
end

update_order_single!(s::SampleMultiAlgRSWRSKIP, r) = nothing
function update_order_single!(s::SampleMultiOrdAlgRSWRSKIP, r)
    s.ord[r] = n_seen(s)
end

update_order_multi!(s::SampleMultiAlgRSWRSKIP, r, j) = nothing
function update_order_multi!(s::SampleMultiOrdAlgRSWRSKIP, r, j)
    s.ord[r], s.ord[j] = s.ord[j], n_seen(s)
end

is_ordered(s::AbstractOrdWrReservoirSampleMulti) = true
is_ordered(s::AbstractWrReservoirSampleMulti) = false

function Base.merge(s1::AbstractWrReservoirSampleMulti, s2::AbstractWrReservoirSampleMulti)
    len1, len2, n1, n2 = check_merging_support(s1, s2)
    shuffle!(s1.rng, s1.value)
    shuffle!(s2.rng, s2.value)
    n_tot = n1 + n2
    p = n2 / n_tot
    value = create_new_res_vec(s1, s2, p, len1)
    s_merged = SampleMultiAlgRSWRSKIP(0, n_tot, s1.rng, value)
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
    n1, n2 = n_seen(s1), n_seen(s2)
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
    if n_seen(s) < length(s.value)
        return s.value[1:n_seen(s)]
    else
        return s.value
    end
end
function value(s::AbstractWrReservoirSampleMulti)
    if n_seen(s) < length(s.value)
        return sample(s.rng, s.value[1:n_seen(s)], length(s.value))
    else
        return s.value
    end
end

function ordered_value(s::AbstractOrdWorReservoirSampleMulti)
    if n_seen(s) < length(s.value)
        return s.value[1:n_seen(s)]
    else
        return s.value[sortperm(s.ord)]
    end
end
function ordered_value(s::AbstractOrdWrReservoirSampleMulti)
    if n_seen(s) < length(s.value)
        return sample(s.rng, s.value[1:n_seen(s)], length(s.value); ordered=true)
    else
        return s.value[sortperm(s.ord)]
    end
end

function itsample(iter, n::Int, method::ReservoirAlgorithm = algL; ordered = false)
    return itsample(Random.default_rng(), iter, n, method; ordered)
end
function itsample(rng::AbstractRNG, iter, n::Int, method::ReservoirAlgorithm = algL; ordered = false)
    iter_type = calculate_eltype(iter)
    if Base.IteratorSize(iter) isa Base.SizeUnknown
        reservoir_sample(rng, iter, n, method; ordered)::Vector{iter_type}
    else
        replace = method isa AlgL || method isa AlgR ? false : true
        sortedindices_sample(rng, iter, n; replace, ordered)::Vector{iter_type}
    end
end

function reservoir_sample(rng, iter, n::Int, method::ReservoirAlgorithm = algL; ordered = false)
    iter_type = calculate_eltype(iter)
    s = ReservoirSample(rng, iter_type, n, method; ordered = ordered)
    return update_all!(s, iter, ordered)
end

function update_all!(s, iter, ordered)
    for x in iter
        s = update!(s, x)
    end
    return ordered ? ordered_value(s) : shuffle!(s.rng, value(s))
end

function calculate_eltype(iter)
    T = eltype(iter)
    return T === Any ? Base.@default_eltype(iter) : T
end
