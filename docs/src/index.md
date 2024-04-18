
## Introduction

The scope of this package is providing general methods to sample from any stream in a single pass through the data, even when the number of items contained in the stream is unknown.

This has some advantages over other sampling procedures:

- If the iterable is lazy, the memory required grows in relation to the size of the sample, instead of the all population.
- The sample collected is a random sample of the portion of the stream seen thus far at any point of the sampling process.

## Brief overview of the functionalities

The [`itsample`](@ref) function allows to consume all the stream at once and return the sample collected:

```julia
julia> using StreamSampling

julia> st = 1:100;

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

```julia
julia> using StreamSampling

julia> rs = ReservoirSample(Int, 5);

julia> for x in 1:100
           update!(rs, x)
       end

julia> value(rs)
5-element Vector{Int64}:
  7
  9
 20
 49
 74
```

Consult the [API page](https://juliadynamics.github.io/StreamSampling.jl/stable/api/) for more information on these and other functionalities.
