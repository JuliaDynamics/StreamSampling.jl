
# UnWeighted

function itsample(iter; replace = false, alloc = false)
    return itsample(Random.GLOBAL_RNG, iter; 
                    replace = replace, alloc = alloc)
end

function itsample(rng::AbstractRNG, iter; replace = false, alloc = false)
    if alloc
        if replace
            error("Not implemented yet")
        else
            unweighted_sampling(iter, rng)
        end
    else
        if replace
            error("Not implemented yet")
        else
            IterHasKnownSize = Base.IteratorSize(iter)
            unweighted_resorvoir_sampling(iter, rng, IterHasKnownSize)
        end
    end
end

function itsample(condition::Function, iter, replace = false, alloc = false)
    return itsample(Random.GLOBAL_RNG, condition, iter; 
                    replace = replace, alloc = alloc)
end

function itsample(
    rng::AbstractRNG, condition::Function, iter; 
    replace = false, alloc = false
)
    if alloc 
        if replace
            error("Not implemented yet")
        else
            conditioned_unweighted_sampling(iter, rng, condition)
        end
    else
        if replace
            error("Not implemented yet")
        else
            iter_filtered = Iterators.filter(x -> condition(x), iter)
            IterHasKnownSize = Base.IteratorSize(iter_filtered)
            unweighted_resorvoir_sampling(iter_filtered, rng, IterHasKnownSize)
        end
    end
end

# Weighted

function itsample(
    iter, wv::Function; 
    replace = false, alloc = true, iter_type = Any
)
    return itsample(Random.GLOBAL_RNG, iter, wv; 
                    replace = replace, alloc = alloc, iter_type = iter_type)
end

function itsample(
    rng::AbstractRNG, iter, wv::Function; 
    replace = false, alloc = true, iter_type = Any
)
    return error("Not implemented yet")
end

function itsample(
    condition::Function, iter, wv::Function; 
    replace = false, alloc = true, iter_type = Any
)
    return itsample(Random.GLOBAL_RNG, condition, iter, wv; 
                    replace = replace, alloc = alloc, iter_type = iter_type)
end 

function itsample(
    rng::AbstractRNG, condition::Function, iter, wv::Function; 
    replace = false, alloc = true, iter_type = Any
)
    return error("Not implemented yet")
end

# ALGORITHMS

function unweighted_sampling(iter, rng)
    pop = collect(iter)
    isempty(pop) && return nothing
    return rand(rng, pop)
end

function conditioned_unweighted_sampling(iter, rng, condition)
    pop = collect(iter)
    n_p = length(pop)
    while n_p != 0
        idx = rand(rng, 1:n_p)
        el = pop[idx]
        condition(el) && return el
        pop[idx], pop[n_p] = pop[n_p], pop[idx]
        n_p -= 1
    end
    return nothing
end

function unweighted_resorvoir_sampling(iter, rng, ::NonIndexable)
    res = iterate(iter)
    isnothing(res) && return nothing
    w = rand(rng)
    while true
        choice, state = res
        skip_counter = floor(log(rand(rng))/log(1-w))
        while skip_counter != 0
            skip_res = iterate(iter, state)
            isnothing(skip_res) && return choice
            state = skip_res[2]
            skip_counter -= 1
        end
        res = iterate(iter, state)
        isnothing(res) && return choice
        w *= rand(rng)
    end
end

function unweighted_resorvoir_sampling(iter, rng, ::Indexable)
    k = rand(rng, 1:length(iter))
    for (i, x) in enumerate(iter)
        i == k && return x
    end
end


