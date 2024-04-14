
function sortedindices_sample(rng, iter, n::Int; replace = false, ordered = false, kwargs...)
    N = length(iter)
    if N <= n
        reservoir = collect(iter)
        if replace
            return sample(rng, reservoir, n, ordered=ordered)
        else
            if ordered
                return reservoir
            else
                return shuffle!(rng, reservoir)
            end
        end
    end
    iter_type = Base.@default_eltype(iter)
    reservoir = Vector{iter_type}(undef, n)
    indices = get_sorted_indices(rng, n, N, replace)
    first_idx = indices[1]
    it = iterate(iter)
    el, state = it
    if first_idx != 1
        it = skip_ahead_no_end(iter, state, first_idx - 2)
        el, state = it
    end
    reservoir[1] = el
    i = 2
    @inbounds while i <= n
        skip_k = indices[i] - indices[i-1] - 1
        if skip_k < 0
            reservoir[i] = el
        else
            it = skip_ahead_no_end(iter, state, skip_k)
            el, state = it
            reservoir[i] = el
        end
        i += 1
    end
    if ordered
        return reservoir
    else
        return shuffle!(rng, reservoir)
    end
end

function skip_ahead_no_end(iter, state, n)
    for _ in 1:n
        it = iterate(iter, state)
        state = it[2]
    end
    it = iterate(iter, state)
    return it
end

function get_sorted_indices(rng, n, N, replace)
    if replace == true
        return sortedrandrange(rng, 1:N, n)
    else
        return sort!(sample(rng, 1:N, n; replace=replace))
    end
end

function sortedrandrange(rng, range, n)
    exp_rands = randexp(rng, n)
    sorted_rands = accumulate!(+, exp_rands, exp_rands)
    a, b = range.start, range.stop
    range_size = b-a+1
    cum_step = (sorted_rands[end] + randexp(rng)) / range_size
    sorted_rands ./= cum_step
    return ceil.(Int, sorted_rands)
end
