
"""
    sortedindices_sample(rng, iter)
    sortedindices_sample(rng, iter, n; replace = false, ordered = false)

Algorithm which generates sorted random indices used to retrieve the sample 
from the iterable. The number of elements in the iterable needs to be known 
before starting the sampling.
"""
function sortedindices_sample(rng, iter, n::Int; 
        iter_type = infer_eltype(iter), replace = false, ordered = false)
    N = length(iter)
    if N <= n
        reservoir = collect(iter)
        replace && return sample(rng, reservoir, n, ordered=ordered)
        return ordered ? reservoir : shuffle!(rng, reservoir)
    end
    reservoir = Vector{iter_type}(undef, n)
    indices = get_sorted_indices(rng, n, N, replace)
    first_idx = indices[1]
    el, state = iterate(iter)::Tuple
    if first_idx != 1
        el, state = skip_ahead_no_end(iter, state, first_idx - 2)
    end
    reservoir[1] = el
    i = 2
    @inbounds while i <= n
        skip_k = indices[i] - indices[i-1] - 1
        if skip_k >= 0
            el, state = skip_ahead_no_end(iter, state, skip_k)
        end
        reservoir[i] = el
        i += 1
    end
    return ordered ? reservoir : shuffle!(rng, reservoir)
end

function skip_ahead_no_end(iter, state, n)
    for _ in 1:n
        it = iterate(iter, state)::Tuple
        state = it[2]
    end
    it = iterate(iter, state)::Tuple
    return it
end
