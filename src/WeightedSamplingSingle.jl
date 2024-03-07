
function itsample(iter, wv::Function; replace = false, ordered = false)
    return itsample(Random.default_rng(), iter, wv; replace = replace, ordered = ordered)
end

function itsample(rng::AbstractRNG, iter, wv::Function; replace = false, ordered = false)
    return error("Not implemented yet")
end
