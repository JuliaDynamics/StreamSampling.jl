## Benchmark Comparison

Using these sampling techniques can bring down considerably the memory usage of the program, 
but there are cases where they are also more time efficient, as demostrated below with a comparison with the 
equivalent methods of `StatsBase.sample`:

![image](https://github.com/user-attachments/assets/5ca9637b-606a-4325-bf59-7c601df41fd6)

The “collection-based with setup” methods consider collecting the iterator in memory as part of the benchmark.
The code to reproduce this benchmark is in [benchmark_comparison_stream.jl](https://github.com/JuliaDynamics/StreamSampling.jl/blob/main/benchmark/benchmark_comparison_stream.jl).
