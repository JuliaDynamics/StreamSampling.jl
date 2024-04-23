# StreamSampling.jl

[![CI](https://github.com/JuliaDynamics/StreamSampling.jl/workflows/CI/badge.svg)](https://github.com/JuliaDynamics/StreamSampling.jl/actions/workflows/ci.yml)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliadynamics.github.io/StreamSampling.jl/stable/)
[![codecov](https://codecov.io/gh/JuliaDynamics/StreamSampling.jl/graph/badge.svg?token=F8W0MC53Z0)](https://codecov.io/gh/JuliaDynamics/StreamSampling.jl)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

The scope of this package is to provide general methods to sample from any stream in a single pass through the data, even when 
the number of items contained in the stream is unknown.

This has some advantages over other sampling procedures:

- If the iterable is lazy, the memory required grows in relation to the size of the sample, instead of the all population.
- The sample collected is a random sample of the portion of the stream seen thus far at any point of the sampling process.
- In some cases, sampling with the techniques implemented in this library can bring considerable performance gains, since
  the population of items doesn't need to be previously stored in memory.
  
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

## Benchmark

As stated in the first section, using these sampling techniques can bring down considerably the memory usage of the program, 
but there are cases where they are also more time efficient, as demostrated below with a comparison with the 
equivalent methods of `StatsBase.sample`:

```julia
julia> using StreamSampling

julia> using BenchmarkTools, Random, StatsBase

julia> rng = Xoshiro(42);

julia> iter = Iterators.filter(x -> x != 10, 1:10^7);

julia> wv(el) = 1.0

julia> @btime itsample($rng, $iter, 10^4, algRSWRSKIP);
  11.744 ms (5 allocations: 156.39 KiB)

julia> @btime sample($rng, collect($iter), 10^4; replace=true);
  131.933 ms (20 allocations: 146.91 MiB)

julia> @btime itsample($rng, $iter, 10^4, algL);
  10.260 ms (3 allocations: 78.22 KiB)

julia> @btime sample($rng, collect($iter), 10^4; replace=false);
  132.069 ms (27 allocations: 147.05 MiB)

julia> @btime itsample($rng, $iter, $wv, 10^4, algWRSWRSKIP);
  32.278 ms (18 allocations: 547.34 KiB)

julia> @btime sample($rng, collect($iter), Weights($wv.($iter)), 10^4; replace=true);
  348.220 ms (49 allocations: 675.21 MiB)

julia> @btime itsample($rng, $iter, $wv, 10^4, algAExpJ);
  39.965 ms (11 allocations: 234.78 KiB)

julia> @btime sample($rng, collect($iter), Weights($wv.($iter)), 10^4; replace=false);
  306.039 ms (43 allocations: 370.19 MiB)
```
