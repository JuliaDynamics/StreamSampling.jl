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

For information about the available functionalities consult the [documentation](https://juliadynamics.github.io/StreamSampling.jl/stable/)

## Contributing

Contributions are welcome! If you encounter any issues, have suggestions for improvements, or would like to add new 
features, feel free to open an issue or submit a pull request.
