
function itsample(iter, n::Int; 
        replace = false, ordered = false, is_stateful = false)
    return itsample(Random.GLOBAL_RNG, iter, n; 
                    replace=replace, ordered=ordered, is_stateful=is_stateful)
end

function itsample(rng::AbstractRNG, iter, n::Int; 
        replace = false, ordered = false, is_stateful = false)
    IterHasKnownSize = Base.IteratorSize(iter)
    if IterHasKnownSize isa NonIndexable
        if is_stateful
            if replace
                error("Not implemented yet")
            else
                unweighted_resorvoir_sampling(rng, iter, n)
            end
        else
            unweighted_resorvoir_sampling(rng, iter, n)
            #double_scan_sampling(rng, iter, n, replace, ordered)
        end
    else
        unweighted_resorvoir_sampling(rng, iter, n)
        #single_scan_sampling(rng, iter, n, replace, ordered)
    end
end

function unweighted_resorvoir_sampling(rng, iter, n::Int)
    iter_type = eltype(iter)
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
    while true
        w = exp(-u/n)
        skip_counter = ceil(Int, randexp(rng)/log(1-w))
        while skip_counter != 0
            skip_res = iterate(iter, state)
            isnothing(skip_res) && return reservoir
            state = skip_res[2]
            skip_counter += 1
        end
        it = iterate(iter, state)
        isnothing(it) && return reservoir
        el, state = it
        reservoir[rand(rng, 1:n)] = el 
        u += randexp(rng)
    end
end

function double_scan_sampling(rng, iter, n::Int, replace, ordered)
    N = get_population_size(iter)
    single_scan_sampling(iter, rng, n, N, replace, ordered)
end

function single_scan_sampling(rng, iter, n::Int, replace, ordered)
    return single_scan_sampling(rng, iter, n, length(iter), replace, ordered)
end

function single_scan_sampling(rng, iter, n::Int, N::Int, replace, ordered)
    N <= n && return collect(iter)
    iter_type = eltype(iter)
    indices = sort!(sample(rng, 1:N, n; replace=replace))
    reservoir = Vector{iter_type}(undef, n)
    j = 1
    i = 1
    for (i, x) in enumerate(iter)
        @inbounds while i == indices[j]
            reservoir[j] = x
            if j == n
                if ordered
                    return reservoir
                else
                    return shuffle!(reservoir)
                end
            end
            j += 1
        end
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
