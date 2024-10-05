# StreamSampling.jl

[![CI](https://github.com/JuliaDynamics/StreamSampling.jl/workflows/CI/badge.svg)](https://github.com/JuliaDynamics/StreamSampling.jl/actions?query=workflow%3ACI)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliadynamics.github.io/StreamSampling.jl/stable/)
[![codecov](https://codecov.io/gh/JuliaDynamics/StreamSampling.jl/graph/badge.svg?token=F8W0MC53Z0)](https://codecov.io/gh/JuliaDynamics/StreamSampling.jl)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![DOI](https://zenodo.org/badge/692407431.svg)](https://zenodo.org/doi/10.5281/zenodo.12826684)

The scope of this package is to provide general methods to sample from any stream in a single pass through the data, even when 
the number of items contained in the stream is unknown.

This has some advantages over other sampling procedures:

- If the iterable is lazy, the memory required grows in relation to the size of the sample, instead of the all population.
- The sample collected is a random sample of the portion of the stream seen thus far at any point of the sampling process.
- In some cases, sampling with the techniques implemented in this library can bring considerable performance gains, since
  the population of items doesn't need to be previously stored in memory.
  
## Brief overview of the functionalities

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

Consult the [API page](https://juliadynamics.github.io/StreamSampling.jl/stable/) for more information on these and other functionalities.

## Benchmark

As stated in the first section, using these sampling techniques can bring down considerably the memory usage of the program, 
but there are cases where they are also more time efficient, as demostrated below with a comparison with the 
equivalent methods of `StatsBase.sample`:

```julia
julia> using StreamSampling

julia> using BenchmarkTools, Random, StatsBase

julia> rng = Xoshiro(42);

julia> iter = Iterators.filter(x -> x != 10, 1:10^7);

julia> wv(el) = 1.0;

julia> @btime itsample($rng, $iter, 10^4, AlgRSWRSKIP());
  12.457 ms (4 allocations: 156.34 KiB)

julia> @btime sample($rng, collect($iter), 10^4; replace=true);
  134.152 ms (20 allocations: 146.91 MiB)

julia> @btime itsample($rng, $iter, 10^4, AlgL());
  8.262 ms (2 allocations: 78.17 KiB)

julia> @btime sample($rng, collect($iter), 10^4; replace=false);
  138.054 ms (27 allocations: 147.05 MiB)

julia> @btime itsample($rng, $iter, $wv, 10^4, AlgWRSWRSKIP());
  14.479 ms (15 allocations: 547.23 KiB)

julia> @btime sample($rng, collect($iter), Weights($wv.($iter)), 10^4; replace=true);
  343.936 ms (49 allocations: 675.21 MiB)

julia> @btime itsample($rng, $iter, $wv, 10^4, AlgAExpJ());
  30.523 ms (6 allocations: 234.62 KiB)

julia> @btime sample($rng, collect($iter), Weights($wv.($iter)), 10^4; replace=false);
  294.242 ms (43 allocations: 370.19 MiB)
```

Some more performance comparisons in respect to `StatsBase` methods are in the [benchmark](https://github.com/JuliaDynamics/StreamSampling.jl/blob/main/benchmark/) folder. 



## Contributing

Contributions are welcome! If you encounter any issues, have suggestions for improvements, or would like to add new 
features, feel free to open an issue or submit a pull request.

