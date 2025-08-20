
struct MultiAlgWeightedORDSampler{T,R,I,F}
    rng::R
    it::I
    f::F
    n::Int
    W::Float64
    function MultiAlgWeightedORDSampler{T}(rng::R, it::I, f::F, n, W) where {T,R,I,F}
        return new{T,R,I,F}(rng, it, f, n, W)
    end
end

@inline function Base.iterate(s::MultiAlgWeightedORDSampler)
    local el, state_el
    w, curx, k = 0.0, 0.0, 0
    for i in s.n:-1:1
        curx += (1-exp(-randexp(s.rng)/i))*(1-curx)
        while w < curx * s.W
            nstate = k == 0 ? iterate(s.it) : iterate(s.it, state_el)
            nstate == nothing && return nothing
            k += 1
            el, state_el = nstate
            w += s.f(el)
        end
        return (el, (el, w, state_el, curx, i-1))
    end
    return nothing
end
@inline function Base.iterate(s::MultiAlgWeightedORDSampler, state)
    el, w, state_el, curx, n = state
    for i in n:-1:1
        curx += (1-exp(-randexp(s.rng)/i))*(1-curx)
        while w < curx * s.W
            nstate = iterate(s.it, state_el)
            nstate == nothing && return nothing
            el, state_el = nstate
            w += s.f(el)
        end
        return (el, (el, w, state_el, curx, i-1))
    end
    return nothing
end

Base.IteratorEltype(::MultiAlgWeightedORDSampler) = Base.HasEltype()
Base.eltype(::MultiAlgWeightedORDSampler{T}) where T = T
Base.IteratorSize(::MultiAlgWeightedORDSampler) = Base.HasLength()
Base.length(s::MultiAlgWeightedORDSampler) = s.n

struct MultiAlgORDSampler{T,R,I,D} <: AbstractStreamSampler
    rng::R
    it::I
    n::Int
    inds::D
    function MultiAlgORDSampler{T}(rng::R, it::I, n, inds::D) where {T,R,I,D}
        return new{T,R,I,D}(rng, it, n, inds)
    end
end

function StreamSampler{T}(rng::AbstractRNG, iter, wfunc::Function, n, W, ::AlgORDWSWR) where T
    return MultiAlgWeightedORDSampler{T}(rng, iter, wfunc, n, W)
end
function StreamSampler{T}(rng::AbstractRNG, iter, n, N, ::AlgD) where T
    return MultiAlgORDSampler{T}(rng, iter, min(n, N), SeqSampleIter(rng, N, min(n, N)))
end
function StreamSampler{T}(rng::AbstractRNG, iter, n, N, ::AlgHiddenShuffle) where T
    return MultiAlgORDSampler{T}(rng, iter, min(n, N), SeqIterHiddenShuffleSampler(rng, N, min(n, N)))
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
