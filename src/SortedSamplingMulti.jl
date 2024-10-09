
"""
    sortedindices_sample(rng, iter)
    sortedindices_sample(rng, iter, n; replace = false, ordered = false)

Algorithm which generates sorted random indices used to retrieve the sample 
from the iterable. The number of elements in the iterable needs to be known 
before starting the sampling.
"""
function sortedindices_sample(rng, iter, n::Int, replace; 
        iter_type = infer_eltype(iter), ordered = false)
    N = length(iter)
    if N <= n
        reservoir = collect(iter)
        replace isa Replace && return sample(rng, reservoir, n, ordered=ordered)
        return ordered ? reservoir : shuffle!(rng, reservoir)
    end
    reservoir = Vector{iter_type}(undef, n)
    indices = get_sorted_indices(rng, n, N, replace)
    curr_idx, state_idx = iterate(indices)
    el, state_el = iterate(iter)::Tuple
    for _ in 1:curr_idx-1
        el, state_el = iterate(iter, state_el)::Tuple
    end
    reservoir[1] = el
    @inbounds for i in 2:n
        next_idx, state_idx = iterate(indices, state_idx)
        for _ in 1:next_idx-curr_idx
            el, state_el = iterate(iter, state_el)::Tuple
        end
        reservoir[i] = el
        curr_idx = next_idx
    end
    return ordered ? reservoir : shuffle!(rng, reservoir)
end
