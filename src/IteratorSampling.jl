module IteratorSampling

using Distributions
using Random
using StatsBase

Indexable = Union{Base.HasLength, Base.HasShape}
NonIndexable = Base.SizeUnknown

include("SortedRand.jl")
include("UnweightedSamplingSingle.jl")
include("UnweightedSamplingMulti.jl")

"""
    itsample([rng], iter)

Return a random element of the iterator, optionally specifying a `rng` 
(which defaults to `Random.default_rng()`). If the iterator is empty, it 
returns `nothing`.

-----

    itsample([rng], iter, n::Int; replace = true, ordered = false)

Return a vector of `n` random elements of the iterator, 
optionally specifying a `rng` (which defaults to `Random.default_rng()`).

`replace` dictates whether sampling is performed with replacement. 
`ordered` dictates whether an ordered sample (also called a sequential 
sample, i.e. a sample where items appear in the same order as in `iter`).

If the iterator has less than `n` elements, it returns a vector of 
these elements.

"""
function itsample end

export itsample

end
