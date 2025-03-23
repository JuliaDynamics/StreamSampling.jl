
function sorted_sample_single(rng, iter)
    k = rand(rng, Random.Sampler(rng, 1:length(iter), Val(1)))
    for (i, el) in enumerate(iter)
        i == k && return el
    end
end
