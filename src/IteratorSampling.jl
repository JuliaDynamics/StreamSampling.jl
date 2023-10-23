module IteratorSampling

using StatsBase, Random


Indexable = Union{Base.HasLength, Base.HasShape}
NonIndexable = Base.SizeUnknown

include("SortedRand.jl")
include("UnweightedSamplingSingle.jl")
include("UnweightedSamplingMulti.jl")

"""
    itsample([rng], iter, [condition::Function]; [alloc])

Return a random element of the iterator, optionally specifying a `rng` 
(which defaults to `Random.GLOBAL_RNG`) and a condition to restrict the
sampling on only those elements for which the function returns `true`. 
If the iterator is empty or no random element satisfies the condition, 
it returns `nothing`.

## Keywords
* `alloc = false`: this keyword chooses the algorithm to perform, if
  `alloc = false` the algorithm doesn't allocate a new collection to 
  perform the sampling, which should be better when the number of elements is
  large.

-----

    itsample([rng], iter, [condition::Function], n::Int; [alloc, iter_type])

Return a vector of `n` random elements of the iterator without replacement, 
optionally specifying a `rng` (which defaults to `Random.GLOBAL_RNG`) and 
a condition to restrict the sampling on only those elements for which the 
function returns `true`. If the iterator has less than `n` elements or less 
than `n` elements satisfy the condition, it returns a vector of these elements.

## Keywords
* `alloc = true`: when the function returns a vector, it happens to be much
  better to use the allocating version for small iterators.
* `iter_type = Any`: the iterator type of the given iterator, if not given
  it defaults to `Any`, which means that the returned vector will be also of
  `Any` type. For performance reasons, if you can infer the type of the iterator, 
  it is better to pass it.
"""
function itsample end

export itsample

end
