
"""
    ReservoirSample([rng], T, method = AlgRSWRSKIP())
    ReservoirSample([rng], T, n::Int, method = AlgL(); ordered = false)

Initializes a reservoir sample which can then be fitted with [`fit!`](@ref).
The first signature represents a sample where only a single element is collected.
If `ordered` is true, the reservoir sample values can be retrived in the order
they were collected with [`ordvalue`](@ref).

Look at the [`Sampling Algorithms`](@ref) section for the supported methods. 
"""
function ReservoirSample(T, method::ReservoirAlgorithm = AlgRSWRSKIP())
    return ReservoirSample(Random.default_rng(), T, method, MutSample())
end
function ReservoirSample(rng::AbstractRNG, T, method::ReservoirAlgorithm = AlgRSWRSKIP())
    return ReservoirSample(rng, T, method, MutSample())
end
Base.@constprop :aggressive function ReservoirSample(T, n::Integer, method::ReservoirAlgorithm=AlgL(); 
        ordered = false)
    return ReservoirSample(Random.default_rng(), T, n, method, MutSample(), ordered ? Ord() : Unord())
end
Base.@constprop :aggressive function ReservoirSample(rng::AbstractRNG, T, n::Integer, 
        method::ReservoirAlgorithm=AlgL(); ordered = false)
    return ReservoirSample(rng, T, n, method, MutSample(), ordered ? Ord() : Unord())
end

"""
    fit!(rs::AbstractReservoirSample, el)
    fit!(rs::AbstractReservoirSample, el, w)

Updates the reservoir sample by taking into account the element passed.
If the sampling is weighted also the weight of the elements needs to be
passed.
"""
@inline OnlineStatsBase.fit!(s::AbstractReservoirSample, el) = OnlineStatsBase._fit!(s, el)
@inline OnlineStatsBase.fit!(s::AbstractReservoirSample, el, w) = OnlineStatsBase._fit!(s, el, w)

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

"""
    ordvalue(rs::AbstractReservoirSample)

Returns the elements collected in the sample at the current 
sampling stage in the order they were collected. This applies
only when `ordered = true` is passed in [`ReservoirSample`](@ref).
"""
ordvalue(s::AbstractReservoirSample) = error("Not an ordered sample")

"""
    nobs(rs::AbstractReservoirSample)

Returns the total number of elements that have been observed so far 
during the sampling process.
"""
OnlineStatsBase.nobs(s::AbstractReservoirSample) = s.seen_k

"""
    Base.empty!(rs::AbstractReservoirSample)

Resets the reservoir sample to its initial state. 
Useful to avoid allocating a new sample in some cases.
"""
function Base.empty!(::AbstractReservoirSample)
    error("Abstract Version")
end

"""
    Base.merge!(rs::AbstractReservoirSample, rs::AbstractReservoirSample...)

Updates the first reservoir sample by merging its value with the values
of the other samples. Currently only supported for samples with replacement.
"""
function Base.merge!(::AbstractReservoirSample)
    error("Abstract Version")
end


"""
    Base.merge(rs::AbstractReservoirSample...)

Creates a new reservoir sample by merging the values
of the samples passed. Currently only supported for sample
with replacement.
"""
function OnlineStatsBase.merge(::AbstractReservoirSample)
    error("Abstract Version")
end

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
optionally specifying a `rng` (which defaults to `Random.default_rng()`)
a weight function `wfunc` and a `method`. `ordered` dictates whether an 
ordered sample (also called a sequential sample, i.e. a sample where items 
appear in the same order as in `iter`) must be collected.

If the iterator has less than `n` elements, in the case of sampling without
replacement, it returns a vector of those elements.

-----

    itsample(rngs, iters, n::Int)
    itsample(rngs, iters, wfuncs, n::Int)

Parallel implementation which returns a sample with replacement of size `n`
from the multiple iterables. All the arguments except from `n` must be tuples.
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
        s = ReservoirSample(rng, iter_type, method, ImmutSample())
        return update_all!(s, iter)
    else 
        return sortedindices_sample(rng, iter)
    end
end
Base.@constprop :aggressive function itsample(rng::AbstractRNG, iter, n::Int, method = AlgL(); 
        iter_type = infer_eltype(iter), ordered = false)
    if Base.IteratorSize(iter) isa Base.SizeUnknown
        s = ReservoirSample(rng, iter_type, n, method, ImmutSample(), ordered ? Ord() : Unord())
        return update_all!(s, iter, ordered)
    else
        replace = method isa AlgL || method isa AlgR ? false : true
        sortedindices_sample(rng, iter, n; iter_type, replace, ordered)
    end
end
function itsample(rng::AbstractRNG, iter, wv::Function, method = AlgWRSWRSKIP(); iter_type = infer_eltype(iter))
    s = ReservoirSample(rng, iter_type, method, ImmutSample())
    return update_all!(s, iter, wv)
end
Base.@constprop :aggressive function itsample(rng::AbstractRNG, iter, wv::Function, n::Int, method = AlgAExpJ(); 
        iter_type = infer_eltype(iter), ordered = false)
    s = ReservoirSample(rng, iter_type, n, method, ImmutSample(), ordered ? Ord() : Unord())
    return update_all!(s, iter, ordered, wv)
end
function itsample(rngs::Tuple, iters::Tuple, n::Int,; iter_types = infer_eltype.(iters))
    n_it = length(iters)
    vs = Vector{Vector{Union{iter_types...}}}(undef, n_it)
    ps = Vector{Float64}(undef, n_it)
    Threads.@threads for i in 1:n_it
        s = ReservoirSample(rngs[i], iter_types[i], n, AlgRSWRSKIP(), ImmutSample(), Unord())
        vs[i], ps[i] = update_all_p!(s, iters[i])
    end
    ps /= sum(ps)
    return shuffle!(rngs[1], reduce_samples(rngs, ps, vs))
end
function itsample(rngs::Tuple, iters::Tuple, wfuncs::Tuple, n::Int; iter_types = infer_eltype.(iters))
    n_it = length(iters)
    vs = Vector{Vector{Union{iter_types...}}}(undef, n_it)
    ps = Vector{Float64}(undef, n_it)
    Threads.@threads for i in 1:n_it
        s = ReservoirSample(rngs[i], iter_types[i], n, AlgWRSWRSKIP(), ImmutSample(), Unord())
        vs[i], ps[i] = update_all_p!(s, iters[i], wfuncs[i])
    end
    ps /= sum(ps)
    return shuffle!(rngs[1], reduce_samples(rngs, ps, vs))
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
    return ordered ? ordvalue(s) : shuffle!(s.rng, value(s))
end
function update_all!(s, iter, ordered, wv)
    for x in iter
        s = fit!(s, x, wv(x))
    end
    return ordered ? ordvalue(s) : shuffle!(s.rng, value(s))
end

function update_all_p!(s, iter)
    for x in iter
        s = fit!(s, x)
    end
    return value(s), s.seen_k
end
function update_all_p!(s, iter, wv)
    for x in iter
        s = fit!(s, x, wv(x))
    end
    return value(s), s.state
end