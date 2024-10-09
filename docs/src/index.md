
# StreamSampling.jl

```@docs
StreamSampling
```

# Overview of the functionalities

The `itsample` function allows to consume all the stream at once and return the sample collected:

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

In some cases, one needs to control the updates the `ReservoirSample` will be subject to. In this case
you can simply use the `fit!` function to update the reservoir:

```julia
julia> using StreamSampling

julia> rs = ReservoirSample(Int, 5);

julia> for x in 1:100
           fit!(rs, x)
       end

julia> value(rs)
5-element Vector{Int64}:
  7
  9
 20
 49
 74
```

If the total number of elements in the stream is known beforehand and the sampling is unweighted, it is
also possible to iterate over a `StreamSample` like so

```julia
julia> using StreamSampling

julia> iter = 1:100;

julia> ss = StreamSample{Int}(iter, 5, 100);

julia> r = Int[];

julia> for x in ss
           push!(r, x)
       end

julia> r
5-element Vector{Int64}:
 10
 22
 26
 35
 75
```

Consult the [API page](https://juliadynamics.github.io/StreamSampling.jl/stable/api) for more information about the package interface.
