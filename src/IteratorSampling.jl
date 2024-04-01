module IteratorSampling

using DataStructures
using Distributions
using Random
using ResumableFunctions
using StatsBase

struct WRSample end
struct OrdWRSample end
struct WORSample end
struct OrdWORSample end

const wrsample = WRSample()
const ordwrsample = OrdWRSample()
const worsample = WORSample()
const ordworsample = OrdWORSample()

struct AlgL end
struct AlgR end
struct AlgARes end
struct AlgAExpJ end

const algL = AlgL()
const algR = AlgR()
const algARes = AlgARes()
const algAExpJ = AlgAExpJ()

include("SortedRand.jl")
include("UnweightedSamplingSingle.jl")
include("UnweightedSamplingMulti.jl")
include("WeightedSamplingSingle.jl")
include("WeightedSamplingMulti.jl")

"""
    itsample([rng], iter, [weight]; kwargs...)

Return a random element of the iterator, optionally specifying a `rng` 
(which defaults to `Random.default_rng()`) and a `weight` function.
If the iterator is empty, it returns `nothing`.

-----

    itsample([rng], iter, [weight], n::Int; replace = false, ordered = false, kwargs...)

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
    reservoir_sample(rng, iter, [weight]; method = :alg_L)
    reservoir_sample(rng, iter, [weight], n; replace = false, ordered = false, kwargs...)

Reservoir sampling algorithm with and without replacement.

The optional `kwargs` are passed to more specific methods called internally by the 
function, which can either be [`reservoir_sample_without_replacement`](@ref), 
[`reservoir_sample_with_replacement`](@ref) or [`weighted_reservoir_sample_without_replacement`](@ref),
depending to the kind of sampling performed.
"""
function reservoir_sample end

export reservoir_sample

"""
    reservoir_sample_without_replacement(rng, iter, n; ordered = false, method = :alg_L)

Reservoir sampling algorithm without replacement. The `method` keyword can be either `:alg_L` or
`:alg_R`.

Adapted from algorithms R and L described in "Random sampling with a reservoir, Jeffrey S. Vitter, 1985".
"""
function reservoir_sample_without_replacement end

export reservoir_sample_without_replacement

"""
    reservoir_sample_with_replacement(rng, iter, n; ordered = false)

Reservoir sampling algorithm with replacement.

Adapted fron algorithm RSWR_SKIP described in "Reservoir-based Random Sampling with Replacement from 
Data Stream, Byung-Hoon Park et al., 2008".
"""
function reservoir_sample_with_replacement end

export reservoir_sample_with_replacement

"""
    weighted_reservoir_sample_without_replacement(rng, iter, wv, n; ordered = false, method = :alg_AExpJ)

Weighted reservoir sampling algorithm without replacement. The `method` keyword can be 
either `:alg_ARes` or `:alg_AExpJ`. 

Adapted from algorithm A-Res and A-ExpJ described in "Weighted random sampling with a reservoir, 
Efraimidis et al., 2006". 
"""
function weighted_reservoir_sample_without_replacement end

export weighted_reservoir_sample_without_replacement

"""
    weighted_reservoir_sample_with_replacement(rng, iter, wv, n; ordered = false)

Weighted reservoir sampling algorithm without replacement. 

Adapted from algorithm WRSWR_SKIP described in "A Skip-based Algorithm for Weighted Reservoir 
Sampling with Replacement, Meligrana, 2024". 
"""
function weighted_reservoir_sample_with_replacement end

export weighted_reservoir_sample_with_replacement

"""
    sortedindices_sample(rng, iter)
    sortedindices_sample(rng, iter, n; replace = false, ordered = false)

Algorithm which generates sorted random indices used to retrieve the sample 
from the iterable. The number of elements in the iterable needs to be known 
before starting the sampling.
"""
function sortedindices_sample end

export sortedindices_sample

end
