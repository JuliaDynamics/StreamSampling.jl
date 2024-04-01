
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
        weighted_reservoir_sample_with_replacement(rng, iter, wv, n; ordered)
    else
        weighted_reservoir_sample_without_replacement(rng, iter, wv, n; ordered, kwargs...)
    end
end

function weighted_reservoir_sample_with_replacement(rng, iter, wv, n; ordered = false)
    if ordered
        return error("Not implemented yet")
    else
        weighted_reservoir_sample_with_replacement(rng, iter, wv, n, wrsample)
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

function weighted_reservoir_sample_with_replacement(rng, iter, wv, n, is::Union{WRSample, OrdWRSample})
    iter_type = IteratorSampling.calculate_eltype(iter)
    it = iterate(iter)
    isnothing(it) && return iter_type[]
    reservoir = Vector{iter_type}(undef, n)
    ws = Vector{Float64}(undef, n)
    el, state = it
    w_el = wv(el)
    reservoir[1], ws[1] = el, w_el
    w_sum = wv(el)
    @inbounds for i in 2:n
        it = iterate(iter, state)
        isnothing(it) && return sample(rng, resize!(reservoir, i-1), weights(resize!(ws, i-1)), n)
        el, state = it
        w_el = wv(el)
        reservoir[i], ws[i] = el, w_el
        w_sum += w_el
    end
    reservoir = sample(rng, reservoir, weights(ws), n)
    empty!(ws)
    @inbounds while true
        w_skip = skip(rng, w_sum, n)
        it, w_sum = skip_ahead_unknown_end(iter, state, wv, w_sum, w_skip)
        isnothing(it) && return shuffle!(rng, reservoir)
        el, state = it
        p = wv(el)/w_sum
        z = (1-p)^(n-3)
        q = rand(rng, Uniform(z*(1-p)*(1-p)*(1-p),1))
        k = choose(n, p, q, z)
        if k == 1
            r = rand(rng, 1:n)
            reservoir[r] = el
        else
            for j in 1:k
                r = rand(rng, j:n)
                reservoir[r] = el
                reservoir[r], reservoir[j] = reservoir[j], reservoir[r]
            end
        end 
    end
end

function skip_ahead_unknown_end(iter, state, wv::Function, w_sum, w_skip)
    it = iterate(iter, state)
    isnothing(it) && return nothing, nothing
    el, state = it
    w_sum += wv(el)
    while w_skip > w_sum
        it = iterate(iter, state)
        isnothing(it) && return nothing, nothing
        el, state = it
        w_sum += wv(el)
    end
    return it, w_sum
end

function skip(rng, w_sum::AbstractFloat, m)
    q = rand(rng)^(1/m)
    return w_sum/q
end
