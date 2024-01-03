using Documenter
using IteratorSampling

makedocs(
    modules = [IteratorSampling],
    sitename = "IteratorSampling.jl"),
    pages = [
        "API" => "api.md",
    ],
)
