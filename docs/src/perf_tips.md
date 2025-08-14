# Performance Tips

## Use Immutable Reservoir Samplers

By default, a `ReservoirSampler` is mutable, however, it is
also possible to use an immutable version which supports
all the basic operations. It uses `Accessors.jl` under the
hood to update the reservoir.

Let's compare the performance of mutable and immutable samplers
with a simple benchmark

```@example 1
using StreamSampling, BenchmarkTools

function fit_iter!(rs, iter)
    for i in iter
        rs = fit!(rs, i) # the reassignment is necessary when `rs` is immutable
    end
    return rs
end

iter = 1:10^7;
```

Running with both version we get

```julia
@btime fit_iter!(rs, $iter) setup=(rs = ReservoirSampler{Int}(10, AlgRSWRSKIP(); mutable = true))
```
```julia
  6.535 ms (2 allocations: 144 bytes)
```
```julia
@btime fit_iter!(rs, $iter) setup=(rs = ReservoirSampler{Int}(10, AlgRSWRSKIP(); mutable = false))
```
```julia
  4.816 ms (2 allocations: 144 bytes)
```

As you can see, the immutable version is 50% faster than 
the mutable one. In general, the smaller the ratio between reservoir 
size and stream size, the faster the immutable version
will be than the mutable one. Be careful though, because
calling `fit!` on an immutable sampler won't modify it in-place,
but only create a new updated instance.

## Parallel Sampling from Multiple Streams

Let's say that you want to split the sampling of an iterator. If you can split the iterator into
different partitions then you can update in parallel a reservoir sample for each partition and then
merge them together at the end.

Suppose for instance to have these 2 iterators

```@example 1
iters = [1:100, 101:200]
```

then you create two reservoirs of the same type

```@example 1
rs = [ReservoirSampler{Int}(10, AlgRSWRSKIP()) for i in 1:length(iters)]
```

and after that you can just update them in parallel like so

```@example 1
Threads.@threads for i in 1:length(iters)
    for e in iters[i]
        fit!(rs[i], e)
    end
end
```

then you can obtain a unique reservoir containing a summary of the union of the streams
with

```@example 1
merge(rs...)
```
