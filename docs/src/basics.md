
# Overview of the functionalities

The `itsample` function allows to consume all the stream at once and return the sample collected:

```julia
using StreamSampling

st = 1:100;

itsample(st, 5)
```

In some cases, one needs to control the updates the `ReservoirSampler` will be subject to. In this case
you can simply use the `fit!` function to update the reservoir:

```julia
using StreamSampling

st = 1:100;

rs = ReservoirSampler{Int}(5);

for x in st
    fit!(rs, x)
end

value(rs)
```

If the total number of elements in the stream is known beforehand and the sampling is unweighted, it is
also possible to iterate over a `StreamSampler` like so

```julia
using StreamSampling

st = 1:100;

ss = StreamSampler{Int}(st, 5, 100);

r = Int[];

for x in ss
    push!(r, x)
end

r
```

The advantage of `StreamSampler` iterators in respect to `ReservoirSampler` is that they require `O(1)`
memory if not collected, while reservoir techniques require `O(k)` memory where `k` is the number
of elements in the sample.

Consult the [API page](https://juliadynamics.github.io/StreamSampling.jl/stable/api) for more information
about the package interface.