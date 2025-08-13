
@info "Loading packages..."
using StreamSampling

using BenchmarkTools
using Documenter
using Literate

@info "Building Documentation"
makedocs(
    sitename = "StreamSampling.jl",
    format = Documenter.HTML(prettyurls = false, size_threshold = 409600),
    pages = [
        "StreamSampling.jl" => "index.md",
        "Basics" => "basics.md",
        "An Illustrative Example" => "example.md",
        "API" => "api.md",
        "Performance Tips" => "perf_tips.md", 
        "Benchmarks" => "benchmark.md"
    ],
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