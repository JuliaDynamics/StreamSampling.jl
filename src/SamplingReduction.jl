
const SMWR = Union{SampleMultiAlgRSWRSKIP, SampleMultiAlgWRSWRSKIP}

reduce_samples(t) = error()
function reduce_samples(t, ss::T...) where {T<:SMWR}
    nt = length(ss)
    v = Vector{Vector{get_type_rs(t, ss...)}}(undef, nt)
    ns = rand(ss[1].rng, Multinomial(length(value(ss[1])), get_ps(ss...)))
    Threads.@threads for i in 1:nt
        v[i] = sample(ss[i].rng, value(ss[i]), ns[i]; replace = false)
    end
    return reduce(vcat, v)
end
function reduce_samples(rngs, ps::Vector, vs::Vector)
    nt = length(vs)
    ns = rand(rngs[1], Multinomial(length(vs[1]), ps))
    Threads.@threads for i in 1:nt
        vs[i] = sample(rngs[i], vs[i], ns[i]; replace = false)
    end
    return reduce(vcat, vs)
end

function get_ps(ss::SampleMultiAlgRSWRSKIP...)
    sum_w = sum(getfield(s, :seen_k) for s in ss)
    return [s.seen_k/sum_w for s in ss]
end
function get_ps(ss::SampleMultiAlgWRSWRSKIP...)
    sum_w = sum(getfield(s, :state) for s in ss)
    return [s.state/sum_w for s in ss]
end

get_type_rs(::TypeS, s1::T, ss::T...) where {T<:SMWR} = eltype(value(s1))
function get_type_rs(::TypeUnion, s1::T, ss::T...) where {T<:SMWR}
    return Union{eltype(value(s1)), Union{(eltype(value(s)) for s in ss)...}}
end
