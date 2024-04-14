
mutable struct ResSampleMultiAlgR{T,R} <: AbstractWorReservoirSampleMulti
    state::Int
    rng::R
    value::Vector{T}
end

mutable struct OrdResSampleMultiAlgR{T,R} <: AbstractOrdWorReservoirSampleMulti
    state::Int
    rng::R
    value::Vector{T}
    ord::Vector{Int}
end

mutable struct ResSampleMultiAlgL{T,R} <: AbstractWorReservoirSampleMulti
    state::Float64
    skip_k::Int
    seen_k::Int
    rng::R
    value::Vector{T}
end

mutable struct OrdResSampleMultiAlgL{T,R} <: AbstractOrdWorReservoirSampleMulti
    state::Float64
    skip_k::Int
    seen_k::Int
    rng::R
    value::Vector{T}
    ord::Vector{Int}
end

mutable struct WrResSampleMulti{T,R} <: AbstractWrReservoirSampleMulti
    skip_k::Int
    seen_k::Int
    rng::R
    value::Vector{T}
end

mutable struct OrdWrResSampleMulti{T,R} <: AbstractOrdWrReservoirSampleMulti
    skip_k::Int
    seen_k::Int
    rng::R
    value::Vector{T}
    ord::Vector{Int}
end

function ReservoirSample(T, n::Integer; ordered = false, method=:alg_L)
    return ReservoirSample(Random.default_rng(), T, n; ordered = ordered, method = method)
end
function ReservoirSample(rng::AbstractRNG, T, n::Integer; replace = false, ordered = false, method=:alg_L)
    value = Vector{T}(undef, n)
    if replace
        if ordered
            return OrdWrResSampleMulti(0, 0, rng, value, Vector{Int}(undef, n))
        else
            return WrResSampleMulti(0, 0, rng, value)
        end
    else
        if method == :alg_R
            if ordered
                return OrdResSampleMultiAlgR(0, rng, value, Vector{Int}(undef, n))
            else
                return ResSampleMultiAlgR(0, rng, value)
            end
        else
            if ordered
                return OrdResSampleMultiAlgL(0.0, 0, 0, rng, value, Vector{Int}(undef, n))
            else
                return ResSampleMultiAlgL(0.0, 0, 0, rng, value)
            end
        end
    end
end

function update!(s::Union{ResSampleMultiAlgR, OrdResSampleMultiAlgR}, el)
    n = length(s.value)
    s.state += 1
    if s.state <= n
        s.value[s.state] = el
    else
        j = rand(s.rng, 1:s.state)
        if j <= n
            s.value[j] = el
            update_order!(s, j)
        end
    end
    return s
end

function update!(s::Union{ResSampleMultiAlgL, OrdResSampleMultiAlgL}, el)
    n = length(s.value)
    s.seen_k += 1
    s.skip_k -= 1
    if s.seen_k <= n
        s.value[s.seen_k] = el
        s.seen_k == n && recompute_skip!(s, n)
    elseif s.skip_k < 0
        j = rand(s.rng, 1:n)
        s.value[j] = el
        update_order!(s, j)
        recompute_skip!(s, n)
    end
    return s
end

function update!(s::AbstractWrReservoirSampleMulti, el)
    n = length(s.value)
    s.seen_k += 1
    s.skip_k -= 1
    if s.seen_k <= n
        s.value[s.seen_k] = el
        if s.seen_k == n
            recompute_skip!(s, n)   
            s.value = sample(s.rng, s.value, n, ordered=true)
        end
    elseif s.skip_k < 0
        p = 1/s.seen_k
        z = (1-p)^(n-3)
        q = rand(s.rng, Uniform(z*(1-p)*(1-p)*(1-p),1))
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
        recompute_skip!(s, n)
    end
    return s
end

function recompute_skip!(s::AbstractWorReservoirSampleMulti, n)
    s.state += randexp(s.rng)
    w = exp(-s.state/n)
    s.skip_k = -ceil(Int, randexp(s.rng)/log(1-w))
end

function recompute_skip!(s::AbstractWrReservoirSampleMulti, n)
    q = rand(s.rng)^(1/n)
    m = s.seen_k
    s.skip_k = ceil(Int, m/q - m - 1)
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

update_order_single!(s::WrResSampleMulti, r) = nothing
function update_order_single!(s::OrdWrResSampleMulti, r)
    s.ord[r] = n_seen(s)
end

update_order_multi!(s::WrResSampleMulti, r, j) = nothing
function update_order_multi!(s::OrdWrResSampleMulti, r, j)
    s.ord[r], s.ord[j] = s.ord[j], n_seen(s)
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

n_seen(s::Union{ResSampleMultiAlgR, OrdResSampleMultiAlgR}) = s.state
n_seen(s::Union{ResSampleMultiAlgL, OrdResSampleMultiAlgL}) = s.seen_k
n_seen(s::Union{OrdWrResSampleMulti, WrResSampleMulti}) = s.seen_k

function itsample(iter, n::Int; replace = false, ordered = false, method = :alg_L)
    return itsample(Random.default_rng(), iter, n; replace, ordered, method)
end

function itsample(rng::AbstractRNG, iter, n::Int; 
        replace = false, ordered = false, method = :alg_L)
    iter_type = calculate_eltype(iter)
    if Base.IteratorSize(iter) isa Base.SizeUnknown
        reservoir_sample(rng, iter, n; replace, ordered, method)::Vector{iter_type}
    else
        sortedindices_sample(rng, iter, n; replace, ordered)::Vector{iter_type}
    end
end

function reservoir_sample(rng, iter, n; replace = false, ordered = false, method = :alg_L)
    if replace
        compute_sample(rng, iter, n, ordered, algWRSKIP)
    else
        if method === :alg_L
            compute_sample(rng, iter, n, ordered, algL)
        elseif method === :alg_R
            compute_sample(rng, iter, n, ordered, algR)
        else
            error(lazy"No implemented algorithm was found for specified method $(method)")
        end  
    end
end

function compute_sample(rng, iter, n::Int, ordered, alg)
    iter_type = calculate_eltype(iter)
    s = choose_sample(rng, iter_type, n, ordered, alg)
    for x in iter
        @inline update!(s, x)
    end
    return ordered ? ordered_value(s) : shuffle!(rng, value(s))
end

function choose_sample(rng, iter_type, n, ordered, alg::AlgL)
    return ReservoirSample(rng, iter_type, n; replace = false, ordered = ordered, method = :alg_L)
end

function choose_sample(rng, iter_type, n, ordered, alg::AlgR)
    return ReservoirSample(rng, iter_type, n; replace = false, ordered = ordered, method = :alg_R)
end

function choose_sample(rng, iter_type, n, ordered, alg::AlgWRSKIP)
    return ReservoirSample(rng, iter_type, n; replace = true, ordered = ordered)
end

function calculate_eltype(iter)
    return Base.@default_eltype(iter)
end
function calculate_eltype(iter::ResumableFunctions.FiniteStateMachineIterator)
    return eltype(iter)
end
