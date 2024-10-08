
struct TypeS end
struct TypeUnion end

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
    s = Vector{Int}(undef, n)
    curmax = -log(Float64(range.stop))
    for i in n:-1:1
        curmax += randexp(rng)/i
        @inbounds s[i] = ceil(Int, exp(-curmax))
    end
    return s
end

function get_sorted_indices(rng, n, N, replace)
    replace == true && return sortedrandrange(rng, 1:N, n)
    return sort!(sample(rng, 1:N, n; replace=replace))
end
