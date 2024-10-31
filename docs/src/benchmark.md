## Benchmark Comparison between Streaming and Non-Streaming Methods

Using these sampling techniques can bring down considerably the memory usage of the program, 
but there are cases where they are also more time efficient, as demostrated below with a comparison with the 
equivalent methods of `StatsBase.sample`:

![comparison_stream_algs](https://github.com/user-attachments/assets/b5774a5a-5caf-4ca3-ac21-deff23b3cda4)

The “collection-based with setup” methods consider collecting the iterator in memory as part of the benchmark.
The code to reproduce the results is in [benchmark_comparison_stream.jl](https://github.com/JuliaDynamics/StreamSampling.jl/blob/main/benchmark/benchmark_comparison_stream.jl).
