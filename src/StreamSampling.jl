module StreamSampling

# Use the README as the module docs
@doc let
    path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    read(path, String)
end StreamSampling

isdefined(@__MODULE__, :Memory) || const Memory = Vector # Compat for Julia < 1.11

using Accessors
using DataStructures
using Distributions
using HybridStructs
using OnlineStatsBase
using Random
using StatsBase

export fit!, merge!, value, ordvalue, nobs, itsample
export AbstractReservoirSampler, ReservoirSampler, StreamSampler
export AlgL, AlgR, AlgRSWRSKIP, AlgARes, AlgAExpJ, AlgWRSWRSKIP, AlgD, AlgORDSWR, AlgORDWSWR

struct ImmutSampler end
struct MutSampler end

struct Ord end
struct Unord end

abstract type AbstractStreamSampler end
abstract type AbstractReservoirSampler <: OnlineStat{Any} end
abstract type AbstractWeightedReservoirSampler <: AbstractReservoirSampler end

abstract type StreamAlgorithm end
abstract type ReservoirAlgorithm <: StreamAlgorithm end

"""
Implements random reservoir sampling without replacement. To be used with [`ReservoirSampler`](@ref)
or [`itsample`](@ref).

Adapted from algorithm R described in "Random sampling with a reservoir, J. S. Vitter, 1985".
"""
struct AlgR <: ReservoirAlgorithm end

"""
Implements random reservoir sampling without replacement. To be used with [`ReservoirSampler`](@ref)
or [`itsample`](@ref).

Adapted from algorithm L described in "Random sampling with a reservoir, J. S. Vitter, 1985".
"""
struct AlgL <: ReservoirAlgorithm end

"""
Implements random reservoir sampling with replacement. To be used with [`ReservoirSampler`](@ref)
or [`itsample`](@ref).

Adapted fron algorithm RSWR-SKIP described in "Reservoir-based Random Sampling with Replacement from 
Data Stream, B. Park et al., 2008".
"""
struct AlgRSWRSKIP <: ReservoirAlgorithm end

"""
Implements weighted random reservoir sampling without replacement. To be used with [`ReservoirSampler`](@ref)
or [`itsample`](@ref).

Adapted from algorithm A-Res described in "Weighted random sampling with a reservoir, P. S. Efraimidis
et al., 2006".
"""
struct AlgARes <: ReservoirAlgorithm end

"""
Implements weighted random reservoir sampling without replacement. To be used with [`ReservoirSampler`](@ref)
or [`itsample`](@ref).

Adapted from algorithm A-ExpJ described in "Weighted random sampling with a reservoir, P. S. Efraimidis
et al., 2006".
"""
struct AlgAExpJ <: ReservoirAlgorithm end

"""
Implements weighted random reservoir sampling with replacement. To be used with [`ReservoirSampler`](@ref)
or [`itsample`](@ref).

Adapted from algorithm WRSWR-SKIP described in "Investigating Methods for Weighted Reservoir Sampling with
Replacement, A. Meligrana, 2024".
"""
struct AlgWRSWRSKIP <: ReservoirAlgorithm end

"""
Implements random stream sampling without replacement. To be used with [`StreamSampler`](@ref)
or [`itsample`](@ref).

Adapted from algorithm D described in "An Efficient Algorithm for Sequential Random Sampling,
J. S. Vitter, 1987".
"""
struct AlgD <: StreamAlgorithm end

"""
Implements random stream sampling with replacement. To be used with [`StreamSampler`](@ref)
or [`itsample`](@ref).

Adapted from algorithm 4 described in "Generating Sorted Lists of Random Numbers, J. L. Bentley
et al., 1980".
"""
struct AlgORDSWR <: StreamAlgorithm end

"""
Implements weighted random stream sampling with replacement. To be used with [`StreamSampler`](@ref).

Adapted from algorithm 3 described in "An asymptotically optimal, online algorithm for weighted random
sampling with replacement, M. Startek, 2016".
"""
struct AlgORDWSWR <: StreamAlgorithm end

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
