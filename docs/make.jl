using Documenter
using StreamSampling

println("Documentation Build")
makedocs(
    modules = [StreamSampling],
    sitename = "StreamSampling.jl",
    pages = [  
        "StreamSampling.jl" => "index.md",
        "An Illustrative Example" => "example.md",
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
println("Finished boulding and deploying docs.")
