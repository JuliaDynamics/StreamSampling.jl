# StreamSampling.jl

[![CI](https://github.com/JuliaDynamics/StreamSampling.jl/workflows/CI/badge.svg)](https://github.com/JuliaDynamics/StreamSampling.jl/actions?query=workflow%3ACI)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliadynamics.github.io/StreamSampling.jl/stable/)
[![codecov](https://codecov.io/gh/JuliaDynamics/StreamSampling.jl/graph/badge.svg?token=F8W0MC53Z0)](https://codecov.io/gh/JuliaDynamics/StreamSampling.jl)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)


This package allows to sample from any stream in a single pass through the data, 
even if the number of items is unknown. 

If the iterable is lazy, the memory required grows in relation to the size of the 
sample, instead of the all population, which can be useful for sampling from big 
data streams.

Moreover, it turns out that sampling with the techniques implemented in this library
is also much faster in some common cases, as highlighted below:


```julia
julia> using StreamSampling

julia> using BenchmarkTools, Random, StatsBase

julia> rng = Xoshiro(42);

julia> iter = Iterators.filter(x -> x != 10, 1:10^7);

julia> wv(el) = 1.0

julia> @btime itsample($rng, $iter, 10^4, algRSWRSKIP);
  14.578 ms (5 allocations: 156.39 KiB)

julia> @btime sample($rng, collect($iter), 10^4; replace=true);
  136.139 ms (20 allocations: 146.91 MiB)

julia> @btime itsample($rng, $iter, 10^4, algL);
  10.591 ms (3 allocations: 78.22 KiB)

julia> @btime sample($rng, collect($iter), 10^4; replace=false);
  134.352 ms (27 allocations: 147.05 MiB)

julia> @btime itsample($rng, $iter, $wv, 10^4, algWRSWRSKIP);
  32.892 ms (12 allocations: 568.83 KiB)

julia> @btime sample($rng, collect($iter), Weights($wv.($iter)), 10^4; replace=true);
  545.058 ms (45 allocations: 702.33 MiB)

julia> @btime itsample($rng, $iter, $wv, 10^4, algAExpJ);
  41.092 ms (11 allocations: 234.78 KiB)

julia> @btime sample($rng, collect($iter), Weights($wv.($iter)), 10^4; replace=false);
  312.880 ms (43 allocations: 370.19 MiB)
```

More information can be found in the [documentation](https://juliadynamics.github.io/StreamSampling.jl/stable/).
