
struct MultiAlgORDSampler{T,R,I,D} <: AbstractStreamSampler
    rng::R
    it::I
    n::Int
    inds::D
    function MultiAlgORDSampler{T}(rng::R, it::I, n, inds::D) where {T,R,I,D}
        return new{T,R,I,D}(rng, it, n, inds)
    end
end

function StreamSampler{T}(rng::AbstractRNG, iter, n, N, ::AlgD) where T
    return MultiAlgORDSampler{T}(rng, iter, min(n, N), SeqSampleIter(rng, N, min(n, N)))
end
function StreamSampler{T}(rng::AbstractRNG, iter, n, N, ::AlgORDSWR) where T
    return MultiAlgORDSampler{T}(rng, iter, n, SeqIterWRSampler(rng, N, n))
end

@inline function Base.iterate(s::MultiAlgORDSampler)
    indices, iter = s.inds, s.it
    curr_idx, state_idx = iterate(indices)::Tuple
    el, state_el = iterate(iter)::Tuple
    for _ in 1:curr_idx-1
        el, state_el = iterate(iter, state_el)::Tuple
    end
    return (el, (el, state_el, curr_idx, state_idx))
end
@inline function Base.iterate(s::MultiAlgORDSampler, state)
    el, state_el, curr_idx, state_idx = state
    indices, iter = s.inds, s.it
    it_indices = iterate(indices, state_idx)
    it_indices === nothing && return nothing
    next_idx, state_idx = it_indices
    for _ in 1:next_idx-curr_idx
        el, state_el = iterate(iter, state_el)::Tuple
    end
    return (el, (el, state_el, next_idx, state_idx))
end

Base.IteratorEltype(::MultiAlgORDSampler) = Base.HasEltype()
Base.eltype(::MultiAlgORDSampler{T}) where T = T
Base.IteratorSize(::MultiAlgORDSampler) = Base.HasLength()
Base.length(s::MultiAlgORDSampler) = s.n
