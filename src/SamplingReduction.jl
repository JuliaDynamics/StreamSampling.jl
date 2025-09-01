
const SMWR = Union{MultiAlgRSWRSKIPSampler, MultiAlgWRSWRSKIPSampler}
const SMWOWR = Union{MultiAlgAResSampler, MultiAlgAExpJSampler}

reduce_samples(t) = error()
function reduce_samples(t::Union{TypeS,TypeUnion}, ss::BinaryHeap...)
    nt = length(ss)
    n = minimum(length.(ss))
    lkeys = sort(reduce(vcat, [s.valtree for s in ss]), by=(x->x[end]), rev=true)[1:n]
    return lkeys
end
function reduce_samples(ps::AbstractArray, rngs, t::Union{TypeS,TypeUnion}, ss::AbstractArray...)
    nt = length(ss)
    T = get_type_rs(t, ss...)
    v = Vector{Vector{T}}(undef, nt)
    n = minimum(length.(ss))
    ns = rand(extract_rng(rngs, 1), Multinomial(n, ps))
    Threads.@threads for i in 1:nt
        s = ss[i]
        vi = Vector{T}(undef, ns[i])
        @inbounds for (q, j) in enumerate(SequentialSampler(extract_rng(rngs, i), 
                                          ns[i], length(s), AlgHiddenShuffle()))
            vi[q] = s[j]
        end
        v[i] = vi
    end
    return reduce(vcat, v)
end

extract_rng(v::AbstractArray, i) = v[i]
extract_rng(v::AbstractRNG, i) = v

function get_ps(ss::MultiAlgRSWRSKIPSampler...)
    sum_w = sum(getfield(s, :seen_k) for s in ss)
    return [s.seen_k/sum_w for s in ss]
end
function get_ps(ss::MultiAlgWRSWRSKIPSampler...)
    sum_w = sum(getfield(s, :state) for s in ss)
    return [s.state/sum_w for s in ss]
end

get_type_rs(::TypeS, s1::T, ss::T...) where {T} = eltype(s1)
function get_type_rs(::TypeUnion, s1::T, ss::T...) where {T}
    return Union{eltype(s1), Union{(eltype(s) for s in ss)...}}
end
