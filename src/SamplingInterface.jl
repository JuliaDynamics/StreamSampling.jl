
"""
    ReservoirSampler{T}([rng], method = AlgRSWRSKIP())
    ReservoirSampler{T}([rng], n::Int, method = AlgL(); ordered = false)

Initializes a reservoir sampler with elements of type `T`.

The first signature represents a sample where only a single element is collected.
If `ordered` is true, the sampled values can be retrived in the order
they were collected using [`ordvalue`](@ref).

Look at the [`Sampling Algorithms`](@ref) section for the supported methods. 
"""
struct ReservoirSampler{T,F} 1 === 1 end

ReservoirSampler{T}(args::Vararg{Any, N}; kwargs...) where {T,N} = ReservoirSampler{T,Float64}(args...; kwargs...)

function ReservoirSampler{T,F}(method::ReservoirAlgorithm = AlgRSWRSKIP(); mutable = true) where {T,F}
    return ReservoirSampler{T,F}(Random.default_rng(), method, mutable ? MutSampler() : ImmutSampler())
end
function ReservoirSampler{T,F}(rng::AbstractRNG, method::ReservoirAlgorithm = AlgRSWRSKIP(); mutable = true) where {T,F}
    return ReservoirSampler{T,F}(rng, method, mutable ? MutSampler() : ImmutSampler())
end
Base.@constprop :aggressive function ReservoirSampler{T,F}(n::Integer, method::ReservoirAlgorithm=AlgL(); 
        ordered = false, mutable = true) where {T,F}
    return ReservoirSampler{T,F}(Random.default_rng(), n, method, mutable ? MutSampler() : ImmutSampler(), ordered ? Ord() : Unord())
end
Base.@constprop :aggressive function ReservoirSampler{T,F}(rng::AbstractRNG, n::Integer, 
        method::ReservoirAlgorithm=AlgL(); ordered = false, mutable = true) where {T,F}
    return ReservoirSampler{T,F}(rng, n, method, mutable ? MutSampler() : ImmutSampler(), ordered ? Ord() : Unord())
end

"""
    fit!(rs::AbstractReservoirSampler, el)
    fit!(rs::AbstractReservoirSampler, el, w)

Updates the reservoir sample by taking into account the element passed.
If the sampling is weighted also the weight of the elements needs to be
passed.
"""
@inline OnlineStatsBase.fit!(s::AbstractReservoirSampler, el) = OnlineStatsBase._fit!(s, el)
@inline OnlineStatsBase.fit!(s::AbstractWeightedReservoirSampler, el, w) = OnlineStatsBase._fit!(s, el, w)

"""
    value(rs::AbstractReservoirSampler)

Returns the elements collected in the sample at the current 
sampling stage.

If the sampler is empty, it returns `nothing` for single element
sampling. For multi-valued samplers, it always returns the sample
collected so far instead.

Note that even if the sampling respects the schema it is assigned
when [`ReservoirSampler`](@ref) is instantiated, some ordering in 
the sample can be more probable than others. To represent each one 
with the same probability call `fshuffle!` on the result.
"""
OnlineStatsBase.value(s::AbstractReservoirSampler) = error("Abstract version")

"""
    ordvalue(rs::AbstractReservoirSampler)

Returns the elements collected in the sample at the current 
sampling stage in the order they were collected. This applies
only when `ordered = true` is passed in [`ReservoirSampler`](@ref).

If the sampler is empty, it returns `nothing` for single element
sampling. For multi-valued samplers, it always returns the sample
collected so far instead.
"""
ordvalue(s::AbstractReservoirSampler) = error("Not an ordered sample")

"""
    nobs(rs::AbstractReservoirSampler)

Returns the total number of elements that have been observed so far 
during the sampling process.
"""
OnlineStatsBase.nobs(rs::AbstractReservoirSampler) = rs.seen_k

"""
    Base.empty!(rs::AbstractReservoirSampler)

Resets the reservoir sample to its initial state. 
Useful to avoid allocating a new sampler in some cases.
"""
function Base.empty!(::AbstractReservoirSampler)
    error("Abstract Version")
end

"""
    Base.merge!(rs::AbstractReservoirSampler...)

Updates the first reservoir sampler by merging its value with the values
of the other samplers. The number of elements after merging will be
the minimum number of elements in the merged reservoirs.
"""
function Base.merge!(::AbstractReservoirSampler)
    error("Abstract Version")
end

"""
    Base.merge(rs::AbstractReservoirSampler...)

Creates a new reservoir sampler by merging the values
of the samplers passed. The number of elements in the new
sampler will be the minimum number of elements in the merged
reservoirs.
"""
function OnlineStatsBase.merge(::AbstractReservoirSampler)
    error("Abstract Version")
end

"""
    combine([rng], samples::AbstractArray, weights::AbstractArray)

Combines different stream samples in a single one. The number of 
elements in the new sampler will be the minimum number of elements
in the samples. `weights` should contain the weight of each stream,
which in the unweighted case coincides with the length of the streams.
"""
combine(ss::AbstractArray, ns::AbstractArray) = combine(Random.default_rng(), ss, ns)
combine(rng, ss::AbstractArray, ns::AbstractArray) = reduce_samples(ns./sum(ns), rng, TypeUnion(), ss...)

"""
    Base.size(rs::AbstractReservoirSampler)

Returns the maximum number of elements that are stored in the reservoir.
"""
Base.size(rs::AbstractReservoirSampler) = rs.n

"""
    StreamSampler{T}([rng], iter, n, [N], method = AlgD())

Initializes a stream sampler, which can then be iterated over
to return the sampling elements of the iterable `iter` which
is assumed to have a `eltype` of `T`. The methods implemented in
[`StreamSampler`](@ref) require the knowledge of the total number
of elements in the stream `N`, if not provided it is assumed to be
available by calling `length(iter)`.

-----

    StreamSampler{T}([rng], iter, wfunc, n, W, method = AlgORDWSWR())

Initializes a weigthed stream sampler, which can then be iterated over
to return the sampling elements of the iterable `iter` which
is assumed to have a `eltype` of `T`. The methods implemented in
[`StreamSampler`](@ref) for weighted streams require the knowledge
of the total weight of the stream `W` and a weight function `wfunc`
specifying how to map an element to its weight. 
"""
struct StreamSampler{T} 1 === 1 end

function StreamSampler{T}(iter, wfunc::Function, n, W, method::StreamAlgorithm = AlgORDWSWR()) where T
    return StreamSampler{T}(Random.default_rng(), iter, wfunc, n, W, method)
end
function StreamSampler{T}(rng::AbstractRNG, iter, wfunc::Function, n, W, method::StreamAlgorithm = AlgORDWSWR()) where T
    return StreamSampler{T}(rng, iter, wfunc, n, W, method)
end
function StreamSampler{T}(iter, n, N, method::StreamAlgorithm = AlgD()) where T
    return StreamSampler{T}(Random.default_rng(), iter, n, N, method)
end
function StreamSampler{T}(iter, n, method::StreamAlgorithm = AlgD()) where T
    return StreamSampler{T}(Random.default_rng(), iter, n, length(iter), method)
end
function StreamSampler{T}(rng::AbstractRNG, iter, n, method::StreamAlgorithm = AlgD()) where T
    return StreamSampler{T}(rng, iter, n, length(iter), method)
end
function StreamSampler{T}(rng::AbstractRNG, iter, n, N, method::StreamAlgorithm = AlgD()) where T
    return StreamSampler{T}(rng, iter, n, N, method)
end

"""
    SequentialSampler([rng], n, N, method = AlgD())

Initializes a sequential sampler, which can then be iterated over
to return `n` ordered indices between 1 and `N`, respecting the sampling
scheme of the selected method, which can be `AlgD()`, `AlgHiddenShuffle()`
or `AlgORDSWR()`.
"""
struct SequentialSampler{S}
    s::S
    SequentialSampler(n, N) = SequentialSampler(Random.default_rng(), n, N, AlgD())
    SequentialSampler(n, N, alg) = SequentialSampler(Random.default_rng(), n, N, alg)
    SequentialSampler(rng::AbstractRNG, n, N) = SequentialSampler(rng, n, N, AlgD())
    function SequentialSampler(rng, n, N, ::AlgD)
        return new{SeqSampleIter{typeof(rng)}}(SeqSampleIter(rng, N, n))
    end
    function SequentialSampler(rng, n, N, ::AlgHiddenShuffle)
        return new{SeqIterHiddenShuffleSampler{typeof(rng)}}(SeqIterHiddenShuffleSampler(rng, N, n))
    end
    function SequentialSampler(rng, n, N, ::AlgORDSWR)
        return new{SeqIterWRSampler{typeof(rng)}}(SeqIterWRSampler(rng, N, n))
    end
end
Base.iterate(s::SequentialSampler) = iterate(s.s)
Base.iterate(s::SequentialSampler, state) = iterate(s.s, state)
Base.IteratorEltype(::SequentialSampler) = Base.HasEltype()
Base.eltype(::SequentialSampler) = Int
Base.IteratorSize(::SequentialSampler) = Base.HasLength()
Base.length(s::SequentialSampler) = s.s.n

"""
    itsample([rng], iter, method = AlgRSWRSKIP())
    itsample([rng], iter, wfunc, method = AlgWRSWRSKIP())

Return a random element of the iterator, optionally specifying a `rng` 
(which defaults to `Random.default_rng()`) and a function `wfunc` which
accept each element as input and outputs the corresponding weight.
If the iterator is empty, it returns `nothing`.

-----

    itsample([rng], iter, n::Int, method = AlgL(); ordered = false)
    itsample([rng], iter, wfunc, n::Int, method = AlgAExpJ(); ordered = false)

Return a vector of `n` random elements of the iterator, 
optionally specifying a `rng` (which defaults to `Random.default_rng()`),
a weight function `wfunc` specifying how to map an element to its weight
and a `method`. `ordered` dictates whether an ordered sample (also called a 
sequential sample, i.e. a sample where items  appear in the same order as in
`iter`) must be collected.

If the iterator has less than `n` elements, in the case of sampling without
replacement, it returns a vector of those elements.
"""
function itsample(iter, method = AlgRSWRSKIP(); iter_type = infer_eltype(iter))
    return itsample(Random.default_rng(), iter, method; iter_type)
end
function itsample(iter, n::Int, method = AlgL(); iter_type = infer_eltype(iter), ordered = false)
    return itsample(Random.default_rng(), iter, n, method; ordered)
end
function itsample(iter, wv::Function, method = AlgWRSWRSKIP(); iter_type = infer_eltype(iter))
    return itsample(Random.default_rng(), iter, wv, method)
end
function itsample(iter, wv::Function, n::Int, method = AlgAExpJ(); iter_type = infer_eltype(iter), 
        ordered = false)
    return itsample(Random.default_rng(), iter, wv, n, method; iter_type, ordered)
end
Base.@constprop :aggressive function itsample(rng::AbstractRNG, iter, method = AlgRSWRSKIP();
        iter_type = infer_eltype(iter))
    if Base.IteratorSize(iter) isa Base.SizeUnknown
        s = ReservoirSampler{iter_type,Float64}(rng, method, ImmutSampler())
        return update_all!(s, iter)
    else 
        return sorted_sample_single(rng, iter)
    end
end
Base.@constprop :aggressive function itsample(rng::AbstractRNG, iter, n::Int, method = AlgL(); 
        iter_type = infer_eltype(iter), ordered = false)
    if Base.IteratorSize(iter) isa Base.SizeUnknown
        s = ReservoirSampler{iter_type,Float64}(rng, n, method, ImmutSampler(), ordered ? Ord() : Unord())
        return update_all!(s, iter, ordered)
    else
        m = method isa AlgL || method isa AlgR || method isa AlgD ? AlgD() : AlgORDSWR()
        s = collect(StreamSampler{iter_type}(rng, iter, n, length(iter), m))
        return ordered ? s : fshuffle!(rng, s)
    end
end
function itsample(rng::AbstractRNG, iter, wv::Function, method = AlgWRSWRSKIP(); iter_type = infer_eltype(iter))
    s = ReservoirSampler{iter_type,Float64}(rng, method, ImmutSampler())
    return update_all!(s, iter, wv)
end
Base.@constprop :aggressive function itsample(rng::AbstractRNG, iter, wv::Function, n::Int, method = AlgAExpJ(); 
        iter_type = infer_eltype(iter), ordered = false)
    s = ReservoirSampler{iter_type,Float64}(rng, n, method, ImmutSampler(), ordered ? Ord() : Unord())
    return update_all!(s, iter, ordered, wv)
end

function update_all!(s, iter)
    for x in iter
        s = fit!(s, x)
    end
    return value(s)
end
function update_all!(s, iter, wv)
    for x in iter
        s = fit!(s, x, wv(x))
    end
    return value(s)
end
function update_all!(s, iter, ordered::Bool)
    for x in iter
        s = fit!(s, x)
    end
    return ordered ? ordvalue(s) : fshuffle!(s.rng, value(s))
end
function update_all!(s, iter, ordered, wv)
    for x in iter
        s = fit!(s, x, wv(x))
    end
    return ordered ? ordvalue(s) : fshuffle!(s.rng, value(s))
end
