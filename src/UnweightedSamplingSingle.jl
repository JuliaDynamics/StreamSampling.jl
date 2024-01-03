
function itsample(iter)
    return itsample(Random.default_rng(), iter)
end

function itsample(rng::AbstractRNG, iter)
    IterHasKnownSize = Base.IteratorSize(iter)
    if IterHasKnownSize isa NonIndexable
        return reservoir_sample(rng, iter)
    else 
        return sortedindices_sample(rng, iter)
    end
end

function reservoir_sample(rng, iter)
    res = iterate(iter)
    isnothing(res) && return nothing
    el, state = res
    w = rand(rng)
    while true
        skip_counter = ceil(Int, randexp(rng)/log(1-w))
        while skip_counter != 0
            skip_res = iterate(iter, state)
            isnothing(skip_res) && return el
            state = skip_res[2]
            skip_counter += 1
        end
        res = iterate(iter, state)
        isnothing(res) && return el
        el, state = res
        w *= rand(rng)
    end
end

function double_scan_sampling(rng, iter)
    N = get_population_size(iter)
    sortedindices_sample(rng, iter, N)
end

function sortedindices_sample(rng, iter) 
    return sortedindices_sample(rng, iter, length(iter))
end

function sortedindices_sample(rng, iter, N)
    k = rand(rng, 1:N)
    for (i, x) in enumerate(iter)
        i == k && return x
    end
end


