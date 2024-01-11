
function itsample(iter)
    return itsample(Random.default_rng(), iter)
end

function itsample(rng::AbstractRNG, iter)
    if Base.IteratorSize(iter) isa Base.SizeUnknown
        return reservoir_sample(rng, iter)
    else 
        return sortedindices_sample(rng, iter)
    end
end

function reservoir_sample(rng, iter)
    it = iterate(iter)
    isnothing(it) && return nothing
    el, state = it
    w = rand(rng)
    while true
        skip_k = ceil(Int, randexp(rng)/log(1-w))
        it = skip_ahead_unknown_end(iter, state, skip_k)
        isnothing(it) && return el
        el, state = it
        w *= rand(rng)
    end
end

function sortedindices_sample(rng, iter)
    k = rand(rng, 1:length(iter))
    for (i, x) in enumerate(iter)
        i == k && return x
    end
end


