
@hybrid struct RefVal{T}
    value::T
    RefVal{T}() where T = new{T}()
    RefVal(value::T) where T = new{T}(value)
end

function infer_eltype(itr)
    T1, T2 = eltype(itr), Base.@default_eltype(itr)
    ifelse(T2 !== Union{} && T2 <: T1, T2, T1)
end

function sortedrandrange(rng, range, n)
    exp_rands = randexp(rng, n)
    sorted_rands = cumsum(exp_rands)
    a, b = range.start, range.stop
    range_size = b-a+1
    cum_step = (sorted_rands[end] + randexp(rng)) / range_size
    sorted_rands ./= cum_step
    return ceil.(Int, sorted_rands)
end

function get_sorted_indices(rng, n, N, replace)
    replace == true && return sortedrandrange(rng, 1:N, n)
    return sort!(sample(rng, 1:N, n; replace=replace))
end
