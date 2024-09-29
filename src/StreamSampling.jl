module StreamSampling

import Accessors
using DataStructures
using Distributions
using HybridStructs
using OnlineStatsBase
using Random
using StatsBase

struct ImmutSample end
struct MutSample end

const ims = ImmutSample()
const ms = MutSample()

abstract type AbstractReservoirSample <: OnlineStat{Any} end

# unweighted cases
abstract type AbstractReservoirSampleSingle <: AbstractReservoirSample end
abstract type AbstractReservoirSampleMulti <: AbstractReservoirSample end
abstract type AbstractWorReservoirSampleMulti <: AbstractReservoirSampleMulti end
abstract type AbstractOrdWorReservoirSampleMulti <: AbstractWorReservoirSampleMulti end
abstract type AbstractWrReservoirSampleMulti <: AbstractReservoirSampleMulti end
abstract type AbstractOrdWrReservoirSampleMulti <: AbstractWrReservoirSampleMulti end

# weighted cases
abstract type AbstractWeightedReservoirSample <: AbstractReservoirSample end
abstract type AbstractWeightedReservoirSampleSingle <: AbstractWeightedReservoirSample end
abstract type AbstractWeightedReservoirSampleMulti <: AbstractWeightedReservoirSample end
abstract type AbstractWeightedWorReservoirSampleMulti <: AbstractWeightedReservoirSample end
abstract type AbstractWeightedWrReservoirSampleMulti <: AbstractWeightedReservoirSample end
abstract type AbstractWeightedOrdWrReservoirSampleMulti <: AbstractWeightedReservoirSample end

struct Ord end
struct Unord end

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

export AlgL, AlgR, AlgRSWRSKIP, AlgARes, AlgAExpJ, AlgWRSWRSKIP

macro reset(e)
    s = e.args[1].args[1]
    esc(quote
        if ismutabletype(typeof($s))
            $e
        else
            $StreamSampling.Accessors.@update $e
        end
    end)
end

function infer_eltype(itr)
    T1, T2 = eltype(itr), Base.@default_eltype(itr)
    ifelse(T2 !== Union{} && T2 <: T1, T2, T1)
end

"""
    ReservoirSample([rng], T, method = AlgRSWRSKIP())
    ReservoirSample([rng], T, wfunc, method = AlgWRSWRSKIP())
    ReservoirSample([rng], T, n::Int, method = AlgL(); ordered = false)
    ReservoirSample([rng], T, wfunc, n::Int, method = AlgAExpJ(); ordered = false)

Initializes a reservoir sample which can then be fitted with [`fit!`](@ref).
The first signature represents a sample where only a single element is collected.
A weight function `wfunc` can be passed to apply weighted sampling. Look at the
[`Algorithms`](@ref) section for the supported methods.
"""
Base.@constprop :aggressive function ReservoirSample(T, n::Integer, method::ReservoirAlgorithm=AlgL(); 
        ordered = false)
    return ReservoirSample(Random.default_rng(), T, n, method, ms, ordered ? Ord() : Unord())
end
Base.@constprop :aggressive function ReservoirSample(rng::AbstractRNG, T, n::Integer, 
        method::ReservoirAlgorithm=AlgL(); ordered = false)
    return ReservoirSample(rng, T, n, method, ms, ordered ? Ord() : Unord())
end
Base.@constprop :aggressive function ReservoirSample(T, wv, n::Integer, 
        method::ReservoirAlgorithm=algAExpJ(); ordered = false)
    return ReservoirSample(Random.default_rng(), T, wv, n, method, ms, ordered ? Ord() : Unord())
end
Base.@constprop :aggressive function ReservoirSample(rng::AbstractRNG, T, wv, n::Integer, 
        method::ReservoirAlgorithm=algAExpJ(); ordered = false)
    return ReservoirSample(rng, T, wv, n, method, ms, ordered ? Ord() : Unord())
end

export ReservoirSample

"""
    fit!(rs::AbstractReservoirSample, el)

Updates the reservoir sample by taking into account the element passed.
"""
@inline OnlineStatsBase.fit!(s::AbstractReservoirSample, el) = OnlineStatsBase._fit!(s, el)

export fit!

"""
    value(rs::AbstractReservoirSample)

Returns the elements collected in the sample at the current 
sampling stage.

Note that even if the sampling respects the schema it is assigned
when [`ReservoirSample`](@ref) is instantiated, some ordering in 
the sample can be more probable than others. To represent each one 
with the same probability call `shuffle!` over the result.
"""
OnlineStatsBase.value(s::AbstractReservoirSample) = error("Abstract version")

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
    nobs(rs::AbstractReservoirSample)

Returns the total number of elements that have been observed so far 
during the sampling process.
"""
OnlineStatsBase.nobs(s::AbstractReservoirSample) = s.seen_k

export nobs

"""
    Base.empty!(rs::AbstractReservoirSample)

Resets the reservoir sample to its initial state. 
Useful to avoid allocating a new sample in some cases.
"""
function Base.empty!(::AbstractReservoirSample)
    error("Abstract Version")
end

"""
    itsample([rng], iter, method = algL)
    itsample([rng], iter, weight, method = algAExpJ)

Return a random element of the iterator, optionally specifying a `rng` 
(which defaults to `Random.default_rng()`) and a `weight` function which
accept each element as input and outputs the corresponding weight.
If the iterator is empty, it returns `nothing`.

-----

    itsample([rng], iter, n::Int, method = algL; ordered = false)
    itsample([rng], iter, wv, n::Int, method = algAExpJ; ordered = false)

Return a vector of `n` random elements of the iterator, 
optionally specifying a `rng` (which defaults to `Random.default_rng()`)
and a `method`. `ordered` dictates whether an ordered sample (also called a sequential 
sample, i.e. a sample where items appear in the same order as in `iter`) must be 
collected.

If the iterator has less than `n` elements, in the case of sampling without
replacement, it returns a vector of those elements.
"""
function itsample(iter, method::ReservoirAlgorithm = AlgRSWRSKIP();
        iter_type = infer_eltype(iter))
    return itsample(Random.default_rng(), iter, method; iter_type)
end
function itsample(iter, n::Int, method::ReservoirAlgorithm = AlgL(); 
        iter_type = infer_eltype(iter), ordered = false)
    return itsample(Random.default_rng(), iter, n, method; ordered)
end
function itsample(iter, wv::Function, method::ReservoirAlgorithm = AlgWRSWRSKIP();
        iter_type = infer_eltype(iter))
    return itsample(Random.default_rng(), iter, wv, method)
end
function itsample(iter, wv::Function, n::Int, method::ReservoirAlgorithm=AlgAExpJ(); 
        iter_type = infer_eltype(iter), ordered = false)
    return itsample(Random.default_rng(), iter, wv, n, method; iter_type, ordered)
end
Base.@constprop :aggressive function itsample(rng::AbstractRNG, iter, method::ReservoirAlgorithm = AlgRSWRSKIP();
        iter_type = infer_eltype(iter))
    if Base.IteratorSize(iter) isa Base.SizeUnknown
        return reservoir_sample(rng, iter, iter_type, method)
    else 
        return sortedindices_sample(rng, iter)
    end
end
Base.@constprop :aggressive function itsample(rng::AbstractRNG, iter, n::Int, 
        method::ReservoirAlgorithm = AlgL(); iter_type = infer_eltype(iter), ordered = false)
    if Base.IteratorSize(iter) isa Base.SizeUnknown
        reservoir_sample(rng, iter, n, method; iter_type, ordered)::Vector{iter_type}
    else
        replace = method isa AlgL || method isa AlgR ? false : true
        sortedindices_sample(rng, iter, n; iter_type, replace, ordered)::Vector{iter_type}
    end
end
function itsample(rng::AbstractRNG, iter, wv::Function, method::ReservoirAlgorithm = AlgWRSWRSKIP();
        iter_type = infer_eltype(iter))
    s = ReservoirSample(rng, iter_type, wv, method, ims)
    return update_all!(s, iter)
end
Base.@constprop :aggressive function itsample(rng::AbstractRNG, iter, wv::Function, n::Int, method::ReservoirAlgorithm=AlgAExpJ(); 
        iter_type = infer_eltype(iter), ordered = false)
    s = ReservoirSample(rng, iter_type, wv, n, method, ims, ordered ? Ord() : Unord())
    return update_all!(s, iter, ordered)
end

export itsample

"""
    sortedindices_sample(rng, iter)
    sortedindices_sample(rng, iter, n; replace = false, ordered = false)

Algorithm which generates sorted random indices used to retrieve the sample 
from the iterable. The number of elements in the iterable needs to be known 
before starting the sampling.
"""
function sortedindices_sample end

include("SortedSamplingSingle.jl")
include("SortedSamplingMulti.jl")
include("UnweightedSamplingSingle.jl")
include("UnweightedSamplingMulti.jl")
include("WeightedSamplingSingle.jl")
include("WeightedSamplingMulti.jl")
include("precompile.jl")

end
