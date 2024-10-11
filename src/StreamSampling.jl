module StreamSampling

# Use the README as the module docs
@doc let
    path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    read(path, String)
end StreamSampling

using Accessors
using DataStructures
using Distributions
using HybridStructs
using OnlineStatsBase
using Random
using StatsBase

export fit!, merge!, value, ordvalue, nobs, itsample
export AbstractReservoirSample, ReservoirSample, StreamSample
export AlgL, AlgR, AlgRSWRSKIP, AlgARes, AlgAExpJ, AlgWRSWRSKIP, AlgD, AlgORDSWR

struct ImmutSample end
struct MutSample end

struct Ord end
struct Unord end

abstract type AbstractStreamSample end
abstract type AbstractReservoirSample <: OnlineStat{Any} end

abstract type StreamAlgorithm end
abstract type ReservoirAlgorithm <: StreamAlgorithm end

"""
Implements random sampling without replacement. To be used with [`StreamSample`](@ref)
or [`itsample`](@ref).

Adapted from algorithm D described in "An Efficient Algorithm for Sequential Random Sampling,
J. S. Vitter, 1987".
"""
struct AlgD <: StreamAlgorithm end

"""
Implements random stream sampling with replacement. To be used with [`StreamSample`](@ref)
or [`itsample`](@ref).

Adapted from algorithm 4 described in "Generating Sorted Lists of Random Numbers, J. L. Bentley
et al., 1980".
"""
struct AlgORDSWR <: StreamAlgorithm end

"""
Implements random reservoir sampling without replacement. To be used with [`ReservoirSample`](@ref)
or [`itsample`](@ref).

Adapted from algorithm R described in "Random sampling with a reservoir, J. S. Vitter, 1985".
"""
struct AlgR <: ReservoirAlgorithm end

"""
Implements random reservoir sampling without replacement. To be used with [`ReservoirSample`](@ref)
or [`itsample`](@ref).

Adapted from algorithm L described in "Random sampling with a reservoir, J. S. Vitter, 1985".
"""
struct AlgL <: ReservoirAlgorithm end

"""
Implements random reservoir sampling with replacement. To be used with [`ReservoirSample`](@ref)
or [`itsample`](@ref).

Adapted fron algorithm RSWR-SKIP described in "Reservoir-based Random Sampling with Replacement from 
Data Stream, B. Park et al., 2008".
"""
struct AlgRSWRSKIP <: ReservoirAlgorithm end

"""
Implements weighted random reservoir sampling without replacement. To be used with [`ReservoirSample`](@ref)
or [`itsample`](@ref).

Adapted from algorithm A-Res described in "Weighted random sampling with a reservoir, P. S. Efraimidis
et al., 2006".
"""
struct AlgARes <: ReservoirAlgorithm end

"""
Implements weighted random reservoir sampling without replacement. To be used with [`ReservoirSample`](@ref)
or [`itsample`](@ref).

Adapted from algorithm A-ExpJ described in "Weighted random sampling with a reservoir, P. S. Efraimidis
et al., 2006".
"""
struct AlgAExpJ <: ReservoirAlgorithm end

"""
Implements weighted random reservoir sampling with replacement. To be used with [`ReservoirSample`](@ref)
or [`itsample`](@ref).

Adapted from algorithm WRSWR-SKIP described in "Weighted Reservoir Sampling with Replacement from Multiple
Data Streams, A. Meligrana, 2024". 
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
