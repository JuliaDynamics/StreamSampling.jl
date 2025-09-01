# Benchmarks

## Sampling Iterators

Using these sampling techniques can bring down considerably the memory usage of the program, 
but there are cases where they are also more time efficient:

![](https://github.com/user-attachments/assets/f92becdb-09bd-40c6-8f05-580c0229e83e)

The iterator used is a filtered generator which creates an integer range between `1` and `10^8`. The filtering step is performed to make the
benchmark more accurately mimic a somewhat realistic iterator, on which the methods could be actually used in practice.

The “population” methods use `StatsBase.sample` and consider collecting the iterator in memory as part of the benchmark. The reservoir and stream
methods use instead `ReservoirSampler` and `StreamSampler` of this package.

The code to reproduce the results is at [StreamSampling.jl/benchmark/benchmark_comparison_stream.jl](https://github.com/JuliaDynamics/StreamSampling.jl/blob/main/benchmark/benchmark_comparison_stream.jl).

## Sampling Persistent Data

We also tried to evaluate the performance of the procedures on persistent data. Here we measure the
performance of weighted sampling with replacement from 100 GB of data in the arrow format stored on
disk:

![comparison_ondisk_algs](https://github.com/user-attachments/assets/622c5d03-07f2-428c-9bb5-6d6fcc629bec)

the "chunks" method uses `StatsBase.sample` along with the merging methods of this package to sample
subsequent chunks of the stored data and then recombine the samples. The other methods employ the
same methodologies as in the previous benchmark.

As you can see, using a `ReservoirSampler` in this case beats all other methods. This is partly due to its
single-pass nature, in contrast to streaming methods which usually require two passes (though the first pass
which computes the total weight is faster than the second one which extracts the sample).

The code to reproduce the results is at [StreamSampling.jl/benchmark/benchmark_ondisk.jl](https://github.com/JuliaDynamics/StreamSampling.jl/blob/main/benchmark/benchmark_ondisk.jl).

