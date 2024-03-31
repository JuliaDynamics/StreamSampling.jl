
function itsample(iter, wv::Function)
    return itsample(Random.default_rng(), iter, wv)
end

function itsample(rng::AbstractRNG, iter, wv::Function)
    return reservoir_sample(rng, iter, wv)
end

function reservoir_sample(rng, iter, wv::Function)
    it = iterate(iter)
    isnothing(it) && return nothing
    el, state = it
    chosen = el
    w_el = wv(el)
    w_sum = w_el
    while true
        w_skip = skip(rng, w_sum, 1)
        it, w_sum = skip_ahead_unknown_end(iter, state, wv, w_sum, w_skip)
        isnothing(it) && return chosen
        el, state = it
        chosen = el
    end
end