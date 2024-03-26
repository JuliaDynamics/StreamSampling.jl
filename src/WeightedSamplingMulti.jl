
function itsample(iter, wv::Function, n::Int; 
        replace = false, ordered = false, kwargs...
)
    return itsample(Random.default_rng(), iter, wv, n; 
                    replace = replace, ordered = ordered)
end

function itsample(rng::AbstractRNG, iter, wv::Function, n::Int; 
        replace = false, ordered = false, kwargs...
)
    return reservoir_sample(rng, iter, wv, n; replace, ordered, kwargs...)
end

function reservoir_sample(rng, iter, wv, n; 
        replace = false, ordered = false, kwargs...
)
    if replace
        return error("Not implemented yet")
    else
        weighted_reservoir_sample_without_replacement(rng, iter, wv, n; ordered, kwargs...)
    end
end

function weighted_reservoir_sample_without_replacement(rng, iter, wv, n; ordered = false, method = :alg_AExpJ)
    if ordered
        return error("Not implemented yet")
    else
        if method === :alg_AExpJ
            weighted_reservoir_sample_without_replacement(rng, iter, wv, n, worsample, algAExpJ)
        elseif method === :alg_ARes
            weighted_reservoir_sample_without_replacement(rng, iter, wv, n, worsample, algARes)
        else
            error("No implemented algorithm was found for specified method $(method)")
        end
    end
end

function weighted_reservoir_sample_without_replacement(rng, iter, wv, n, 
        is::Union{WORSample, OrdWORSample}, alg::AlgARes)
    iter_type = calculate_eltype(iter)
    it = iterate(iter)
    isnothing(it) && return iter_type[]
    el, state = it
    reservoir = BinaryHeap(Base.By(last), Pair{iter_type, Float64}[])
    sizehint!(reservoir, n)
    priority = compute_priority_b(rng, wv(el))
    push!(reservoir, el => priority)
    for i in 2:n
        it = iterate(iter, state)
        isnothing(it) && return transform(rng, resize!(first.(reservoir.valtree), i-1), is)
        el, state = it
        priority = compute_priority_b(rng, wv(el))
        push!(reservoir, el => priority)
    end
    while true
        it = iterate(iter, state)
        isnothing(it) && return transform(rng, first.(reservoir.valtree), is)
        el, state = it
        priority = compute_priority_b(rng, wv(el))
        min_priority = last(first(reservoir))
        if priority > min_priority
            pop!(reservoir)
            push!(reservoir, el => priority)
        end
    end
end

compute_priority_b(rng, w_el) = -randexp(rng)/w_el

function weighted_reservoir_sample_without_replacement(rng, iter, wv, n, 
        is::Union{WORSample, OrdWORSample}, alg::AlgAExpJ)
    iter_type = calculate_eltype(iter)
    it = iterate(iter)
    isnothing(it) && return iter_type[]
    el, state = it
    reservoir = BinaryHeap(Base.By(last), Pair{iter_type, Float64}[])
    sizehint!(reservoir, n)
    priority = compute_priority(rng, wv(el))
    push!(reservoir, el => priority)
    for i in 2:n
        it = iterate(iter, state)
        isnothing(it) && return transform(rng, resize!(first.(reservoir.valtree), i-1), is)
        el, state = it
        priority = compute_priority(rng, wv(el))
        push!(reservoir, el => priority)
    end
    while true
        min_priority = last(first(reservoir))
        w_skip = -randexp(rng)/log(min_priority)
        it = skip_ahead_unknown_end(iter, state, wv, w_skip)
        isnothing(it) && return transform(rng, first.(reservoir.valtree), is)
        el, state = it
        priority = compute_skip_priority(rng, min_priority, wv(el))
        pop!(reservoir)
        push!(reservoir, el => priority)
    end
end

function skip_ahead_unknown_end(iter, state, wv::Function, w_skip)
    it = iterate(iter, state)
    isnothing(it) && return nothing
    el, state = it
    w_skip -= wv(el)
    while w_skip > 0.0
        it = iterate(iter, state)
        isnothing(it) && return nothing
        el, state = it
        w_skip -= wv(el)
    end
    return it
end

compute_priority(rng, w_el) = exp(-randexp(rng)/w_el)

function compute_skip_priority(rng, min_priority, w_el)
    t = exp(log(min_priority)*w_el)
    return exp(log(rand(rng, Uniform(t,1)))/w_el)
end

function transform(rng, reservoir, ::WORSample)
    return shuffle!(rng, reservoir)
end
