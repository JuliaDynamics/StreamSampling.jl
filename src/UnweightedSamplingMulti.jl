
function itsample(iter, n::Int; alloc = true, iter_type = Any)
    return itsample(Random.GLOBAL_RNG, iter, n; alloc = alloc, iter_type = iter_type)
end

function itsample(rng::AbstractRNG, iter, n::Int; alloc = true, iter_type = Any)
    if alloc 
        unweighted_sampling_multi(iter, rng, n)
    else
        unweighted_resorvoir_sampling_multi(iter, rng, n, iter_type)
    end
end

function itsample(iter, condition::Function, n::Int; alloc = true, iter_type = Any)
    return itsample(Random.GLOBAL_RNG, iter, condition, n; alloc = alloc, iter_type = iter_type)
end 

function itsample(rng::AbstractRNG, iter, condition::Function, n::Int; alloc = true, iter_type = Any)
    if alloc 
        unweighted_sampling_with_condition_multi(iter, rng, n, condition)
    else
        iter_filtered = Iterators.filter(x -> condition(x), iter)
        unweighted_resorvoir_sampling_multi(iter_filtered, rng, n, iter_type)
    end
end

function unweighted_sampling_multi(iter, rng, n)
    pop = collect(iter)
    length(pop) <= n && return pop
    return sample(rng, pop, n; replace=false)  
end

function unweighted_sampling_with_condition_multi(iter, rng, n, condition)
    pop = collect(iter)
    n_p = length(pop)
    n_p <= n && return filter(el -> condition(el), pop)
    res = Vector{eltype(pop)}(undef, n)
    i = 0
    while n_p != 0
        idx = rand(rng, 1:n_p)
        el = pop[idx]
        if condition(el)
            i += 1
            res[i] = el
            i == n && return res       
        end
        pop[idx], pop[n_p] = pop[n_p], pop[idx]
        n_p -= 1
    end
    return res[1:i] 
end

function unweighted_resorvoir_sampling_multi(iter, rng, n, iter_type = Any)
    it = iterate(iter)
    isnothing(it) && return iter_type[]
    el, state = it
    reservoir = Vector{iter_type}(undef, n)
    reservoir[1] = el
    for i in 2:n
        it = iterate(iter, state)
        isnothing(it) && return reservoir[1:i-1]
        el, state = it
        reservoir[i] = el
    end
    w = rand(rng)^(1/n)
    while true
        skip_counter = floor(log(rand(rng))/log(1-w))
        while skip_counter != 0
            skip_it = iterate(iter, state)
            isnothing(skip_it) && return reservoir
            state = skip_it[2]
            skip_counter -= 1
        end
        it = iterate(iter, state)
        isnothing(it) && return reservoir
        el, state = it
        reservoir[rand(rng, 1:n)] = el 
        w *= rand(rng)^(1/n)
    end
end