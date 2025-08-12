
const SMWR = Union{MultiAlgRSWRSKIPSampler, MultiAlgWRSWRSKIPSampler}
const SMWOWR = Union{MultiAlgAResSampler, MultiAlgAExpJSampler}

reduce_samples(t) = error()
function reduce_samples(t, ss::T...) where {T<:SMWOWR}
    nt = length(ss)
    n = minimum(length.(value.(ss)))
    lkeys = sort(reduce(vcat, [s.value.valtree for s in ss]), by=(x->x[end]), rev=true)[1:n]
    return lkeys
end
function reduce_samples(t, ss::T...) where {T<:SMWR}
    nt = length(ss)
    v = Vector{Vector{get_type_rs(t, ss...)}}(undef, nt)
    n = minimum(length.(value.(ss)))
    ns = rand(ss[1].rng, Multinomial(n, get_ps(ss...)))
    Threads.@threads for i in 1:nt
        v[i] = sample(ss[i].rng, value(ss[i]), ns[i]; replace = false)
    end
    return reduce(vcat, v)
end
function reduce_samples(rngs, ps::Vector, vs::Vector)
    nt = length(vs)
    n = minimum(length.(vs))
    ns = rand(rngs[1], Multinomial(n, ps))
    Threads.@threads for i in 1:nt
        vs[i] = sample(rngs[i], vs[i], ns[i]; replace = false)
    end
    return reduce(vcat, vs)
end

function get_ps(ss::MultiAlgRSWRSKIPSampler...)
    sum_w = sum(getfield(s, :seen_k) for s in ss)
    return [s.seen_k/sum_w for s in ss]
end
function get_ps(ss::MultiAlgWRSWRSKIPSampler...)
    sum_w = sum(getfield(s, :state) for s in ss)
    return [s.state/sum_w for s in ss]
end

get_type_rs(::TypeS, s1::T, ss::T...) where {T} = eltype(value(s1))
function get_type_rs(::TypeUnion, s1::T, ss::T...) where {T}
    return Union{eltype(value(s1)), Union{(eltype(value(s)) for s in ss)...}}
end
