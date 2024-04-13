
function sortedindices_sample(rng, iter; kwargs...)
    k = rand(rng, 1:length(iter))
    for (i, el) in enumerate(iter)
        i == k && return el
    end
end
