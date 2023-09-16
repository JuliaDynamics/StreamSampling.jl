
function itsample(iter; alloc = false)
    return itsample(Random.GLOBAL_RNG, iter; alloc = alloc)
end

function itsample(rng::AbstractRNG, iter; alloc = false)
    if alloc 
        unweighted_sampling_single(iter, rng)
    else
        unweighted_resorvoir_sampling_single(iter, rng)
    end
end

function itsample(iter, condition::Function; alloc = false)
    return itsample(Random.GLOBAL_RNG, iter, condition; alloc = alloc)
end

function itsample(rng::AbstractRNG, iter, condition::Function; alloc = false)
    if alloc 
        unweighted_sampling_with_condition_single(iter, rng, condition)
    else
        iter_filtered = Iterators.filter(x -> condition(x), iter)
        unweighted_resorvoir_sampling_single(iter_filtered, rng)
    end
end


function unweighted_sampling_single(iter, rng)
    pop = collect(iter)
    isempty(pop) && return nothing
    return rand(rng, pop)
end

function unweighted_sampling_with_condition_single(iter, rng, condition)
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

function unweighted_resorvoir_sampling_single(iter, rng)
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