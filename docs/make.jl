
@info "Loading packages..."
using StreamSampling

using BenchmarkTools
using Documenter

@info "Building Documentation"
makedocs(
    sitename = "StreamSampling.jl",
    pages = [
        "Introduction" => "index.md",
        "Basics" => "basics.md",
        "An Illustrative Example" => "example.md",
        "Performance Tips" => "perf_tips.md", 
        "Benchmarks" => "benchmark.md",
        "API" => "api.md",
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
println("Finished building and deploying docs.")
