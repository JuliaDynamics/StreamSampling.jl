
function itsample(iter, wv::Function, n::Int; replace = false, ordered = false)
    return itsample(Random.default_rng(), iter, wv, n; 
                    replace = replace, ordered = ordered)
end

function itsample(rng::AbstractRNG, iter, wv::Function, n::Int; 
    replace = false, ordered = false
)
    return error("Not implemented yet")
end