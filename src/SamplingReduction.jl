
const SMWR = Union{MultiAlgRSWRSKIPSampler, MultiAlgWRSWRSKIPSampler}
const SMWOWR = Union{MultiAlgAResSampler, MultiAlgAExpJSampler}

reduce_samples(t) = error()
function reduce_samples(t::Union{TypeS,TypeUnion}, ss::BinaryHeap...)
    nt = length(ss)
    n = minimum(length.(ss))
    lkeys = sort(reduce(vcat, [s.valtree for s in ss]), by=(x->x[end]), rev=true)[1:n]
    return lkeys
end
function reduce_samples(ps::AbstractArray, rngs, t::Union{TypeS,TypeUnion}, ss::AbstractArray...)
    nt = length(ss)
    v = Vector{Vector{get_type_rs(t, ss...)}}(undef, nt)
    n = minimum(length.(ss))
    ns = rand(extract_rng(rngs, 1), Multinomial(n, ps))
    Threads.@threads for i in 1:nt
        v[i] = sample(extract_rng(rngs, i), ss[i], ns[i]; replace = false)
    end
    return reduce(vcat, v)
end

function reduce_samples_hypergeometric(ps::AbstractArray, rngs, t::Union{TypeS,TypeUnion}, ss::AbstractArray...)
    nt = length(ss)
    v = Vector{Vector{get_type_rs(t, ss...)}}(undef, nt)
    n = minimum(length.(ss))
    
    # For hypergeometric sampling, we need to sample without replacement from finite populations
    # The number of samples from each reservoir depends on hypergeometric distribution
    # Total population size is sum of all reservoir sizes
    total_pop = sum(length.(ss))
    
    # Sample using hypergeometric distribution for each reservoir
    ns = Vector{Int}(undef, nt)
    remaining = n
    remaining_pop = total_pop
    
    for i in 1:(nt-1)
        pop_i = length(ss[i])
        # Use hypergeometric distribution: drawing `remaining` items from population `remaining_pop`
        # where `pop_i` items are of the type we want
        ns[i] = rand(extract_rng(rngs, 1), Hypergeometric(pop_i, remaining_pop - pop_i, remaining))
        remaining -= ns[i]
        remaining_pop -= pop_i
    end
    ns[nt] = remaining  # Remainder goes to last reservoir
    
    Threads.@threads for i in 1:nt
        v[i] = sample(extract_rng(rngs, i), ss[i], ns[i]; replace = false)
    end
    return reduce(vcat, v)
end

extract_rng(v::AbstractArray, i) = v[i]
extract_rng(v::AbstractRNG, i) = v

function get_ps(ss::MultiAlgRSWRSKIPSampler...)
    sum_w = sum(getfield(s, :seen_k) for s in ss)
    return [s.seen_k/sum_w for s in ss]
end
function get_ps(ss::MultiAlgWRSWRSKIPSampler...)
    sum_w = sum(getfield(s, :state) for s in ss)
    return [s.state/sum_w for s in ss]
end
function get_ps(ss::MultiAlgRSampler...)
    sum_w = sum(getfield(s, :seen_k) for s in ss)
    return [s.seen_k/sum_w for s in ss]
end
function get_ps(ss::MultiAlgLSampler...)
    sum_w = sum(getfield(s, :seen_k) for s in ss)
    return [s.seen_k/sum_w for s in ss]
end

get_type_rs(::TypeS, s1::T, ss::T...) where {T} = eltype(s1)
function get_type_rs(::TypeUnion, s1::T, ss::T...) where {T}
    return Union{eltype(s1), Union{(eltype(s) for s in ss)...}}
end
