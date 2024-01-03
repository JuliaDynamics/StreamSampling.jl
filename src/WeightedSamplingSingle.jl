
function itsample(iter, wv::Function; is_stateful = false)
    return itsample(Random.default_rng(), iter, wv; 
                    replace = replace, alloc = alloc, iter_type = iter_type)
end

function itsample(rng::AbstractRNG, iter, wv::Function; is_stateful = false)
    return error("Not implemented yet")
end
