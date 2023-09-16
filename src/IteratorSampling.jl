module IteratorSampling

"""
    itsample(iter, [rng, condition::Function]; [alloc])
Return a random element of the iterator, optionally specifying a `rng` 
(which defaults to `Random.GLOBAL_RNG`) and a condition to restrict the
sampling on only those elements for which the function returns `true`. 
If the iterator is empty or no random element satisfies the condition, 
it returns `nothing`.
## Keywords
* `alloc = false`: this keyword chooses the algorithm to perform, if
`alloc = false` the algorithm doesn't allocate a new collection to 
perform the sampling, which should be better when the number of elements is
large.
    itsample(iter, [rng, condition::Function], n::Int; [alloc, iter_type])
Return a vector of `n` random elements of the iterator, optionally specifying
a `rng` (which defaults to `Random.GLOBAL_RNG`) and a condition to restrict 
the sampling on only those elements for which the function returns `true`. 
If the iterator has less than `n` elements or less than `n` elements satisfy 
the condition, it returns a vector of these elements.
## Keywords
* `alloc = true`: when the function returns a vector, it happens to be much
better to use the allocating version for small iterators.
* `iter_type = Any`: the iterator type of the given iterator, if not given
it defaults to `Any`, which means that the returned vector will be also of
`Any` type. For performance reasons, if you know the type of the iterator, 
it is better to pass it.
"""
function itsample(iter; alloc = false)
    return itsample(iter, Random.GLOBAL_RNG; alloc = alloc)
end

function itsample(iter, rng; alloc = false)
    if alloc 
        sampling_single(iter, rng)
    else
        resorvoir_sampling_single(iter, rng)
    end
end

function itsample(iter, condition::Function; alloc = false)
    return itsample(iter, Random.GLOBAL_RNG, condition; alloc = alloc)
end

function itsample(iter, rng, condition::Function; alloc = false)
    if alloc 
        sampling_with_condition_single(iter, rng, condition)
    else
        iter_filtered = Iterators.filter(x -> condition(x), iter)
        resorvoir_sampling_single(iter_filtered, rng)
    end
end

function itsample(iter, n::Int; alloc = true, iter_type = Any)
    return itsample(iter, Random.GLOBAL_RNG, n; alloc = alloc, iter_type = iter_type)
end

function itsample(iter, rng, n::Int; alloc = true, iter_type = Any)
    if alloc 
        sampling_multi(iter, rng, n)
    else
        resorvoir_sampling_multi(iter, rng, n, iter_type)
    end
end

function itsample(iter, condition::Function, n::Int; alloc = true, iter_type = Any)
    return itsample(iter, Random.GLOBAL_RNG, condition, n; alloc = alloc, iter_type = iter_type)
end 

function itsample(iter, rng, condition::Function, n::Int; alloc = true, iter_type = Any)
    if alloc 
        sampling_with_condition_multi(iter, rng, n, condition)
    else
        iter_filtered = Iterators.filter(x -> condition(x), iter)
        resorvoir_sampling_multi(iter_filtered, rng, n, iter_type)
    end
end

function sampling_single(iter, rng)
    pop = collect(iter)
    isempty(pop) && return nothing
    return rand(rng, pop)
end

function sampling_with_condition_single(iter, rng, condition)
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

function resorvoir_sampling_single(iter, rng)
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

function sampling_multi(iter, rng, n)
    pop = collect(iter)
    pop <= n && return pop
    return sample(rng, pop, n; replace=false)  
end

function sampling_with_condition_multi(iter, rng, n, condition)
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

function resorvoir_sampling_multi(iter, rng, n, iter_type = Any)
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

end
