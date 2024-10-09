
struct SampleMultiAlgORD{T,R,I,D} <: AbstractStreamSample
    rng::R
    it::I
    n::Int
    inds::D
    function SampleMultiAlgORD{T}(rng::R, it::I, n, inds::D) where {T,R,I,D}
        return new{T,R,I,D}(rng, it, n, inds)
    end
end

function StreamSample{T}(rng::AbstractRNG, iter, n, N, ::AlgORDSWR) where T
    return SampleMultiAlgORD{T}(rng, iter, n, SortedRandRangeIter(rng, 1:N, n))
end
function StreamSample{T}(rng::AbstractRNG, iter, n, N, ::AlgORDS) where T
    return SampleMultiAlgORD{T}(rng, iter, min(n, N), sort!(sample(rng, 1:N, min(n, N); replace=false)))
end

@inline function Base.iterate(s::SampleMultiAlgORD)
    indices, iter = s.inds, s.it
    curr_idx, state_idx = iterate(indices)::Tuple
    el, state_el = iterate(iter)::Tuple
    for _ in 1:curr_idx-1
        el, state_el = iterate(iter, state_el)::Tuple
    end
    return (el, (el, state_el, curr_idx, state_idx))
end
@inline function Base.iterate(s::SampleMultiAlgORD, state)
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

Base.IteratorEltype(::SampleMultiAlgORD) = Base.HasEltype()
Base.eltype(::SampleMultiAlgORD{T}) where T = T
Base.IteratorSize(::SampleMultiAlgORD) = Base.HasLength()
Base.length(s::SampleMultiAlgORD) = s.n
