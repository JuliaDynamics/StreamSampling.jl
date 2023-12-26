
function itsample(iter; is_stateful = false)
    return itsample(Random.GLOBAL_RNG, iter; is_stateful = false)
end

function itsample(rng::AbstractRNG, iter; is_stateful = false)
    IterHasKnownSize = Base.IteratorSize(iter)
    if IterHasKnownSize isa NonIndexable
        return unweighted_resorvoir_sampling(rng, iter)
    else 
        return unweighted_resorvoir_sampling(rng, iter)
    end
end

function unweighted_resorvoir_sampling(rng, iter)
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

function single_scan_sampling(rng, iter)
    k = rand(rng, 1:length(iter))
    for (i, x) in enumerate(iter)
        i == k && return x
    end
end


