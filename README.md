# IteratorSampling.jl

[![CI](https://github.com/JuliaDynamics/IteratorSampling.jl/workflows/CI/badge.svg)](https://github.com/JuliaDynamics/IteratorSampling.jl/actions?query=workflow%3ACI)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliadynamics.github.io/IteratorSampling.jl/stable/)
[![codecov](https://codecov.io/gh/JuliaDynamics/IteratorSampling.jl/graph/badge.svg?token=F8W0MC53Z0)](https://codecov.io/gh/JuliaDynamics/IteratorSampling.jl)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)


This package allows to sample from any iterable in a single pass through the data, 
even if the number of items in the collection is unknown. 

If the iterable is lazy, the memory required grows in relation to the size of the 
sample, instead of the all population, which can be useful for sampling from big 
data streams.

Moreover, it turns out that sampling with the techniques implemented in this library
is also much faster in some common cases, as highlighted below:


```julia
julia> using IteratorSampling

julia> using BenchmarkTools, Random, StatsBase

julia> rng = Xoshiro(42);

julia> iter = Iterators.filter(x -> x != 10, 1:10^7);

julia> wv(el) = 1.0

julia> @btime itsample($rng, $iter, 10^4; replace=true);
  9.675 ms (4 allocations: 156.34 KiB)

julia> @btime itsample($rng, $iter, 10^4; replace=false);
  7.889 ms (2 allocations: 78.17 KiB)

julia> @btime itsample($rng, $iter, $wv, 10^4; replace=false);
  20.281 ms (5 allocations: 234.61 KiB)

julia> @btime itsample($rng, $iter, $wv, 10^4; replace=true);
  12.493 ms (15 allocations: 547.23 KiB)

julia> @btime sample($rng, collect($iter), 10^4; replace=true);
  137.932 ms (20 allocations: 146.91 MiB)

julia> @btime sample($rng, collect($iter), 10^4; replace=false);
  139.212 ms (27 allocations: 147.05 MiB)

julia> @btime sample($rng, collect($iter), Weights($wv.($iter)), 10^4; replace=true);
  315.508 ms (49 allocations: 675.21 MiB)

julia> @btime sample($rng, collect($iter), Weights($wv.($iter)), 10^4; replace=false);
  317.230 ms (43 allocations: 370.19 MiB)
```

More information can be found in the [documentation](https://juliadynamics.github.io/IteratorSampling.jl/stable/).
