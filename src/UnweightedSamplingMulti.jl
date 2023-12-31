
function itsample(iter, n::Int; replace = false, ordered = false)
    return itsample(Random.default_rng(), iter, n; replace=replace, ordered=ordered)
end

function itsample(rng::AbstractRNG, iter, n::Int; 
        replace = false, ordered = false)
    IterHasKnownSize = Base.IteratorSize(iter)
    if IterHasKnownSize isa NonIndexable
        if replace
            error("Not implemented yet")
        else
            unweighted_resorvoir_sampling(rng, iter, n, Val(ordered))
        end
    else
        single_scan_sampling(rng, iter, n, replace, ordered)
    end
end

function unweighted_resorvoir_sampling(rng, iter, n::Int, ::Val{false})
    iter_type = Base.@default_eltype(iter)
    it = iterate(iter)
    isnothing(it) && return iter_type[]
    el, state = it
    reservoir = Vector{iter_type}(undef, n)
    reservoir[1] = el
    for i in 2:n
        it = iterate(iter, state)
        isnothing(it) && return shuffle!(reservoir[1:i-1])
        el, state = it
        @inbounds reservoir[i] = el
    end
    u = randexp(rng)
    while true
        w = exp(-u/n)
        skip_counter = ceil(Int, randexp(rng)/log(1-w))
        while skip_counter != 0
            skip_res = iterate(iter, state)
            isnothing(skip_res) && return shuffle!(reservoir)
            state = skip_res[2]
            skip_counter += 1
        end
        it = iterate(iter, state)
        isnothing(it) && return shuffle!(reservoir)
        el, state = it
        @inbounds reservoir[rand(rng, 1:n)] = el 
        u += randexp(rng)
    end
end

function unweighted_resorvoir_sampling(rng, iter, n::Int, ::Val{true})
    iter_type = Base.@default_eltype(iter)
    it = iterate(iter)
    isnothing(it) && return iter_type[]
    el, state = it
    reservoir = Vector{iter_type}(undef, n)
    reservoir[1] = el
    for i in 2:n
        it = iterate(iter, state)
        isnothing(it) && return reservoir[1:i-1]
        el, state = it
        @inbounds reservoir[i] = el
    end
    u = randexp(rng)
    o = [i for i in 1:n]
    k = n
    while true
        w = exp(-u/n)
        skip_counter = ceil(Int, randexp(rng)/log(1-w))
        k += -skip_counter
        while skip_counter != 0
            skip_res = iterate(iter, state)
            isnothing(skip_res) && return reservoir[sortperm(o)]
            state = skip_res[2]
            skip_counter += 1
        end
        it = iterate(iter, state)
        k += 1
        isnothing(it) && return reservoir[sortperm(o)]
        el, state = it
        v = rand(rng, 1:n)
        @inbounds reservoir[v] = el
        @inbounds o[v] = k
        u += randexp(rng)
    end
end

function double_scan_sampling(rng, iter, n::Int, replace, ordered)
    N = get_population_size(iter)
    single_scan_sampling(rng, iter, n, N, replace, ordered)
end

function single_scan_sampling(rng, iter, n::Int, replace, ordered)
    return single_scan_sampling(rng, iter, n, length(iter), replace, ordered)
end

function single_scan_sampling(rng, iter, n::Int, N::Int, replace, ordered)
    if N <= n
        reservoir = collect(iter)
        if ordered
            return reservoir
        else
            return shuffle!(reservoir)
        end
    end
    iter_type = Base.@default_eltype(iter)
    it = iterate(iter)
    el, state = it
    reservoir = Vector{iter_type}(undef, n)
    indices = get_sorted_indices(rng, n, N, replace)
    @inbounds skip_counter = indices[1] - 2
    if skip_counter < 0
        reservoir[1] = el
    else
        while skip_counter != 0
            skip_res = iterate(iter, state)
            state = skip_res[2]
            skip_counter -= 1
        end
        it = iterate(iter, state)
        el, state = it
        @inbounds reservoir[1] = el
    end
    i = 2
    while i <= n
        @inbounds skip_counter = indices[i] - indices[i-1] - 1
        if skip_counter < 0
            @inbounds reservoir[i] = el
        else
            while skip_counter != 0
                skip_res = iterate(iter, state)
                state = skip_res[2]
                skip_counter -= 1
            end
            it = iterate(iter, state)
            el, state = it
            @inbounds reservoir[i] = el
        end
        i += 1
    end
    if ordered
        return reservoir
    else
        return shuffle!(reservoir)
    end
end

function get_population_size(iter)
    n = 0
    it = iterate(iter)
    while !isnothing(it)
        n += 1
        @inbounds state = it[2]
        it = iterate(iter, state)
    end
    return n
end

function get_sorted_indices(rng, n, N, replace)
    if replace == true
        return sortedrandrange(rng, 1:N, n)
    else
        return sort!(sample(rng, 1:N, n; replace=replace))
    end
end