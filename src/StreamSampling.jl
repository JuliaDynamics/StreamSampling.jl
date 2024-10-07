module StreamSampling

using Accessors
using DataStructures
using Distributions
using HybridStructs
using OnlineStatsBase
using Random
using StatsBase

export StreamSampling
export fit!, merge!, value, ordvalue, nobs, itsample
export AbstractReservoirSample, ReservoirSample
export AlgL, AlgR, AlgRSWRSKIP, AlgARes, AlgAExpJ, AlgWRSWRSKIP

struct ImmutSample end
struct MutSample end

struct Ord end
struct Unord end

abstract type AbstractReservoirSample <: OnlineStat{Any} end

abstract type ReservoirAlgorithm end

"""
Implements random sampling without replacement. 

Adapted from algorithm R described in "Random sampling with a reservoir, J. S. Vitter, 1985".
"""
struct AlgR <: ReservoirAlgorithm end

"""
Implements random sampling without replacement.

Adapted from algorithm L described in "Random sampling with a reservoir, J. S. Vitter, 1985".
"""
struct AlgL <: ReservoirAlgorithm end

"""
Implements random sampling with replacement.

Adapted fron algorithm RSWR_SKIP described in "Reservoir-based Random Sampling with Replacement from 
Data Stream, B. Park et al., 2008".
"""
struct AlgRSWRSKIP <: ReservoirAlgorithm end

"""
Implements weighted random sampling without replacement.

Adapted from algorithm A-Res described in "Weighted random sampling with a reservoir, 
P. S. Efraimidis et al., 2006".
"""
struct AlgARes <: ReservoirAlgorithm end

"""
Implements weighted random sampling without replacement.

Adapted from algorithm A-ExpJ described in "Weighted random sampling with a reservoir, 
P. S. Efraimidis et al., 2006".
"""
struct AlgAExpJ <: ReservoirAlgorithm end

"""
Implements weighted random sampling with replacement.

Adapted from algorithm WRSWR_SKIP described in "A Skip-based Algorithm for Weighted Reservoir 
Sampling with Replacement, A. Meligrana, 2024". 
"""
struct AlgWRSWRSKIP <: ReservoirAlgorithm end

include("SamplingUtils.jl")
include("SamplingInterface.jl")
include("SortedSamplingSingle.jl")
include("SortedSamplingMulti.jl")
include("UnweightedSamplingSingle.jl")
include("UnweightedSamplingMulti.jl")
include("WeightedSamplingSingle.jl")
include("WeightedSamplingMulti.jl")
include("SamplingReduction.jl")
include("precompile.jl")

end
