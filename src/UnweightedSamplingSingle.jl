
function itsample(iter; kwargs...)
    return itsample(Random.default_rng(), iter; kwargs...)
end

function itsample(rng::AbstractRNG, iter; kwargs...)
    if Base.IteratorSize(iter) isa Base.SizeUnknown
        return reservoir_sample(rng, iter; kwargs...)
    else 
        return sortedindices_sample(rng, iter; kwargs...)
    end
end

function reservoir_sample(rng, iter; method = :alg_L)
    if method === :alg_L
        reservoir_sample(rng, iter, algL)
    else
        reservoir_sample(rng, iter, algR)
    end
end

function reservoir_sample(rng, iter, alg::AlgL)
    it = iterate(iter)
    isnothing(it) && return nothing
    el, state = it
    w = rand(rng)
    while true
        skip_k = -ceil(Int, randexp(rng)/log(1-w))
        it = skip_ahead_unknown_end(iter, state, skip_k)
        isnothing(it) && return el
        el, state = it
        w *= rand(rng)
    end
end

function reservoir_sample(rng, iter, alg::AlgR)
    it = iterate(iter)
    isnothing(it) && return nothing
    el, state = it
    chosen = el
    k = 1
    while true
        it = iterate(iter, state)
        isnothing(it) && return chosen
        state = it[2]
        k += 1
        rand(rng) < 1/k && (chosen = it[1])
    end
end


function sortedindices_sample(rng, iter; kwargs...)
    k = rand(rng, 1:length(iter))
    for (i, el) in enumerate(iter)
        i == k && return el
    end
end
