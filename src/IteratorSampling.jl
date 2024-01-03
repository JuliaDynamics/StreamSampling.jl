module IteratorSampling

using Distributions
using Random
using StatsBase

Indexable = Union{Base.HasLength, Base.HasShape}
NonIndexable = Base.SizeUnknown

include("SortedRand.jl")
include("UnweightedSamplingSingle.jl")
include("UnweightedSamplingMulti.jl")
include("WeightedSamplingSingle.jl")
include("WeightedSamplingMulti.jl")

"""
    itsample([rng], iter)

Return a random element of the iterator, optionally specifying a `rng` 
(which defaults to `Random.default_rng()`). If the iterator is empty, it 
returns `nothing`.

-----

    itsample([rng], iter, n::Int; replace = false, ordered = false)

Return a vector of `n` random elements of the iterator, 
optionally specifying a `rng` (which defaults to `Random.default_rng()`).

`replace` dictates whether sampling is performed with replacement. 
`ordered` dictates whether an ordered sample (also called a sequential 
sample, i.e. a sample where items appear in the same order as in `iter`).

If the iterator has less than `n` elements, in the case of sampling without
replacement, it returns a vector of those elements.
"""
function itsample end

export itsample

"""
    reservoir_sample(rng, iter)
    reservoir_sample(rng, iter, n, replace, ordered)

Reservoir sampling algorithm with and without replacement.

Adapted from algorithm L described in "Random sampling with a reservoir, Jeffrey S. Vitter, 1985" 
and algorithm RSWR_SKIP described in "Reservoir-based Random Sampling with Replacement from 
Data Stream, Byung-Hoon Park et al., 2008".
"""
function reservoir_sample end

export reservoir_sample

"""
    sortedindices_sample(rng, iter)
    sortedindices_sample(rng, iter, n, replace, ordered)

Faster algorithm than reservoir sampling employed when the number of elements
in the iterable is known. It generates sorted random indices which are used to 
retrieve the sample from the iterable.
"""
function sortedindices_sample end

export sortedindices_sample

end
