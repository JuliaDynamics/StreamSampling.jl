
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

In some cases, one needs to control the updates the `ReservoirSampler` will be subject to. In this case
you can simply use the `fit!` function to update the reservoir:

```julia
julia> using StreamSampling

julia> st = 1:100;

julia> rs = ReservoirSampler{Int}(5);

julia> for x in st
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
also possible to iterate over a `StreamSampler` like so

```julia
julia> using StreamSampling

julia> st = 1:100;

julia> ss = StreamSampler{Int}(st, 5, 100);

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

The advantage of `StreamSampler` iterators in respect to `ReservoirSampler` is that they require `O(1)`
memory if not collected, while reservoir techniques require `O(k)` memory where `k` is the number
of elements in the sample.

Consult the [API page](https://juliadynamics.github.io/StreamSampling.jl/stable/api) for more information
about the package interface.

## Reproducibility

```@raw html
<details><summary>The documentation of StreamSampling.jl was built using these direct dependencies,</summary>
```

```@example
using Pkg # hide
Pkg.status() # hide
```

```@raw html
</details>
```

```@raw html
<details><summary>and using this machine and Julia version.</summary>
```

```@example
using InteractiveUtils # hide
versioninfo() # hide
```

```@raw html
</details>
```

```@raw html
<details><summary>A more complete overview of all dependencies and their versions is also provided.</summary>
```

```@example
using Pkg # hide
Pkg.status(; mode = PKGMODE_MANIFEST) # hide
```

```@raw html
</details>
```

```@eval
using TOML
using Markdown
version = TOML.parse(read("../../Project.toml", String))["version"]
name = TOML.parse(read("../../Project.toml", String))["name"]
link_manifest = "https://github.com/StreamSampling/" * name * ".jl/tree/gh-pages/v" * version *
                "/assets/Manifest.toml"
link_project = "https://github.com/StreamSampling/" * name * ".jl/tree/gh-pages/v" * version *
               "/assets/Project.toml"
Markdown.parse("""You can also download the
[manifest]($link_manifest)
file and the
[project]($link_project)
file.
""")
```
