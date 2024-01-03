using Documenter
using IteratorSampling

println("Documentation Build")
makedocs(
    modules = [IteratorSampling],
    sitename = "IteratorSampling.jl",
    pages = [
        "API" => "api.md",
    ],
)

@info "Deploying Documentation"
if CI
    deploydocs(
        repo = "github.com/Tortar/IteratorSampling.jl.git",
        target = "build",
        push_preview = true,
        devbranch = "main",
    )
end
println("Finished boulding and deploying docs.")
