
function sorted_sample_single(rng, iter)
    k = rand(rng, 1:length(iter))
    for (i, el) in enumerate(iter)
        i == k && return el
    end
end
