module StreamSampling

using DataStructures
using Distributions
using Random
using StatsBase

struct WRSample end
struct OrdWRSample end
struct WORSample end
struct OrdWORSample end

const wrsample = WRSample()
const ordwrsample = OrdWRSample()
const worsample = WORSample()
const ordworsample = OrdWORSample()

abstract type AbstractReservoirSample end

# unweighted cases
abstract type AbstractReservoirSampleMulti <: AbstractReservoirSample end
abstract type AbstractWorReservoirSampleMulti <: AbstractReservoirSampleMulti end
abstract type AbstractOrdWorReservoirSampleMulti <: AbstractWorReservoirSampleMulti end
abstract type AbstractWrReservoirSampleMulti <: AbstractReservoirSampleMulti end
abstract type AbstractOrdWrReservoirSampleMulti <: AbstractWrReservoirSampleMulti end

# weighted cases
abstract type AbstractWeightedReservoirSampleMulti <: AbstractReservoirSample end
abstract type AbstractWeightedWorReservoirSampleMulti <: AbstractReservoirSample end
abstract type AbstractWeightedWrReservoirSampleMulti <: AbstractReservoirSample end
abstract type AbstractWeightedOrdWrReservoirSampleMulti <: AbstractReservoirSample end

abstract type ReservoirAlgorithm end

struct AlgL <: ReservoirAlgorithm end
struct AlgR <: ReservoirAlgorithm end
struct AlgRSWRSKIP <: ReservoirAlgorithm end
struct AlgARes <: ReservoirAlgorithm end
struct AlgAExpJ <: ReservoirAlgorithm end
struct AlgWRSWRSKIP <: ReservoirAlgorithm end

"""
Implements random sampling without replacement.

Adapted from algorithm L described in "Random sampling with a reservoir, J. S. Vitter, 1985".
"""
const algL = AlgL()

"""
Implements random sampling without replacement. 

Adapted from algorithm R described in "Random sampling with a reservoir, J. S. Vitter, 1985".
"""
const algR = AlgR()

"""
Implements random sampling with replacement.

Adapted fron algorithm RSWR_SKIP described in "Reservoir-based Random Sampling with Replacement from 
Data Stream, B. Park et al., 2008".
"""
const algRSWRSKIP = AlgRSWRSKIP()

"""
Implements weighted random sampling without replacement.

Adapted from algorithm A-Res described in "Weighted random sampling with a reservoir, 
P. S. Efraimidis et al., 2006".
"""
const algARes = AlgARes()

"""
Implements weighted random sampling without replacement.

Adapted from algorithm A-ExpJ described in "Weighted random sampling with a reservoir, 
P. S. Efraimidis et al., 2006".
"""
const algAExpJ = AlgAExpJ()

"""
Implements weighted random sampling with replacement.

Adapted from algorithm WRSWR_SKIP described in "A Skip-based Algorithm for Weighted Reservoir 
Sampling with Replacement, A. Meligrana, 2024". 
"""
const algWRSWRSKIP = AlgWRSWRSKIP()

export algL, algR, algRSWRSKIP, algARes, algAExpJ, algWRSWRSKIP

include("SortedSamplingSingle.jl")
include("SortedSamplingMulti.jl")
include("UnweightedSamplingSingle.jl")
include("UnweightedSamplingMulti.jl")
include("WeightedSamplingSingle.jl")
include("WeightedSamplingMulti.jl")


"""

    ReservoirSample([rng], T, method = algL)
    ReservoirSample([rng], T, n::Int, method = algL; ordered = false)

Initializes a reservoir sample which can then be fitted with [`update!`](@ref).
The first signature represents a sample where only a single element is collected.
Look at the [`Algorithms`](@ref) section for the supported methods.
"""
function ReservoirSample end

export ReservoirSample

"""

    update!(rs::AbstractReservoirSample, el, [w])

Updates the reservoir sample by scanning the passed element.
In the case of weighted sampling also the weight of the element
needs to be passed to the function.
"""
function update! end

export update!

"""

    value(rs::AbstractReservoirSample)

Returns the elements collected in the sample at the current 
sampling stage.

Note that even if the sampling respects the schema it is assigned
when [`ReservoirSample`](@ref) is instantiated, some ordering in 
the sample can be more probable than others. To represent each one 
with the same probability call `shuffle!` over the result.
"""
function value end

export value

"""
    ordered_value(rs::AbstractReservoirSample)

Returns the elements collected in the sample at the current 
sampling stage in the order they were collected. This applies
only when `ordered = true` is passed in [`ReservoirSample`](@ref).
"""
function ordered_value end

export ordered_value


"""
    itsample([rng], iter, method = algL)
    itsample([rng], iter, weight, method = algAExpJ)

Return a random element of the iterator, optionally specifying a `rng` 
(which defaults to `Random.default_rng()`) and a `weight` function which
accept each element as input and outputs the corresponding weight.
If the iterator is empty, it returns `nothing`.

-----

    itsample([rng], iter, method = algL; ordered = false)
    itsample([rng], iter, wv, method = algAExpJ; ordered = false)

Return a vector of `n` random elements of the iterator, 
optionally specifying a `rng` (which defaults to `Random.default_rng()`)
and a `method`. `ordered` dictates whether an ordered sample (also called a sequential 
sample, i.e. a sample where items appear in the same order as in `iter`) must be 
collected.

If the iterator has less than `n` elements, in the case of sampling without
replacement, it returns a vector of those elements.
"""
function itsample end

export itsample

"""
    sortedindices_sample(rng, iter)
    sortedindices_sample(rng, iter, n; replace = false, ordered = false)

Algorithm which generates sorted random indices used to retrieve the sample 
from the iterable. The number of elements in the iterable needs to be known 
before starting the sampling.
"""
function sortedindices_sample end

end