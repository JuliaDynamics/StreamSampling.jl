
# Introduction

This package allows to sample from any stream in a single pass through the data, even if the number of items is unknown.

If the iterable is lazy, the memory required grows in relation to the size of the sample, instead of the all population, which can be useful for sampling from big data streams.

# Example Usage

The [`itsample`](@ref) instead allows to consume all the stream at once and return the sample collected:

```
julia> using StreamSampling

julia> st = 1:10;

julia> itsample(st, 5)
5-element Vector{Int64}:
  9
 15
 52
 96
 91
```
In some cases, one needs to control the updates the [`ReservoirSample`](@ref) will be subject to. In this case
you can simply use the [`update!`](@ref) function to fit new values in the reservoir:

```
julia> using StreamSampling

julia> rs = ReservoirSample(Int, 5);

julia> for x in 1:100
           @inline update!(rs, x)
       end

julia> value(rs)
5-element Vector{Int64}:
  7
  9
 20
 49
 74
```

Consult the [API page](https://juliadynamics.github.io/StreamSampling.jl/stable/api/) for more information on the available functionalities.