
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

struct SortedRandRangeIter{R}
    rng::R
    range::UnitRange{Int}
    n::Int
end

@inline function Base.iterate(s::SortedRandRangeIter)
    curmax = -log(Float64(s.range.stop)) + randexp(s.rng)/s.n
    return (s.range.stop - ceil(Int, exp(-curmax)) + 1, (s.n-1, curmax))
end
@inline function Base.iterate(s::SortedRandRangeIter, state)
    state[1] == 0 && return nothing
    curmax = state[2] + randexp(s.rng)/state[1]
    return (s.range.stop - ceil(Int, exp(-curmax)) + 1, (state[1]-1, curmax))
end

Base.IteratorEltype(::SortedRandRangeIter) = Base.HasEltype()
Base.eltype(::SortedRandRangeIter) = Int
Base.IteratorSize(::SortedRandRangeIter) = Base.HasLength()
Base.length(s::SortedRandRangeIter) = s.n
