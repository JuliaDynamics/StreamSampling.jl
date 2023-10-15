
function itsample(iter, n::Int; alloc = true, iter_type = Any)
    return itsample(Random.GLOBAL_RNG, iter, n; alloc = alloc, iter_type = iter_type)
end

function itsample(rng::AbstractRNG, iter, n::Int; alloc = true, iter_type = Any)
    if alloc 
        unweighted_sampling_multi(iter, rng, n)
    else
        IterHasKnownSize = Base.IteratorSize(iter)
        unweighted_resorvoir_sampling_multi(iter, rng, n, IterHasKnownSize, iter_type)
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
        IterHasKnownSize = Base.IteratorSize(iter_filtered)
        unweighted_resorvoir_sampling_multi(iter_filtered, rng, n, IterHasKnownSize, iter_type)
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

function unweighted_resorvoir_sampling_multi(iter, rng, n, ::Base.SizeUnknown, iter_type = eltype(iter))
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

function unweighted_resorvoir_sampling_multi(iter, rng, n, ::Union{Base.HasLength, Base.HasShape}, iter_type = eltype(iter))
    N = length(iter)
    N <= n && return collect(iter)
    indices = sort!(sample(rng, 1:N, n; replace=false))
    reservoir = Vector{iter_type}(undef, n)
    j = 1
    for (i, x) in enumerate(iter)
        if i == indices[j]
            reservoir[j] = x
            j == n && return reservoir
            j += 1
        end
    end
end