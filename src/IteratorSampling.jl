module IteratorSampling

using Distributions
using Random
using StatsBase

struct WRSample end
struct OrdWRSample end
struct WORSample end
struct OrdWORSample end

const initstate = InitialState()
const wrsample = WRSample()
const ordwrsample = OrdWRSample()
const worsample = WORSample()
const ordworsample = OrdWORSample()

struct InitialState end

const initstate = InitialState()

struct SamplingIter{T}
    iter::T
    n_seen::Base.RefValue{Int}
end

function SamplingIter(iter)
    return SamplingIter(iter, Ref(0))
end

function Base.iterate(samplingiter::SamplingIter)
    samplingiter.n_seen[] += 1
    iterate(samplingiter.iter)
end

function Base.iterate(samplingiter::SamplingIter, ::InitialState)
    samplingiter.n_seen[] += 1
    iterate(samplingiter.iter)
end

function Base.iterate(samplingiter::SamplingIter, state)
    samplingiter.n_seen[] += 1
    iterate(samplingiter.iter, state)
end

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

-----

    itsample([rng], iter, sample, n_seen; replace = false, ordered = false)

Restart the sampling, from an already collected sample, 
"""
function itsample end

export itsample

function SamplingIter end
"""

"""

export SamplingIter
"""
    SamplingIter(iter)

A wrapper around the iterator to sample needed when the sampling could be
restarted at a later stage, in this case, some state variable needs to be
mantained, for its use case see [`itsample`](@ref) accepting a previously 
collected sample as an argument.
"""

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
