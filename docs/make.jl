using Documenter

using BenchmarkTools
using StreamSampling

println("Documentation Build")
makedocs(
    modules = [StreamSampling],
    sitename = "StreamSampling.jl",
    pages = [  
        "StreamSampling.jl" => "index.md",
        "Basics" => "basics.md",
        "An Illustrative Example" => "example.md",
        "API" => "api.md",
        "Performance Tips" => "perf_tips.md", 
        "Benchmarks" => "benchmark.md"
    ],
    warnonly = [:doctest, :missing_docs, :cross_references],
)

@info "Deploying Documentation"
CI = get(ENV, "CI", nothing) == "true" || get(ENV, "GITHUB_TOKEN", nothing) !== nothing
if CI
    deploydocs(
        repo = "github.com/JuliaDynamics/StreamSampling.jl.git",
        target = "build",
        push_preview = true,
        devbranch = "main",
    )
end
println("Finished boulding and deploying docs.")
