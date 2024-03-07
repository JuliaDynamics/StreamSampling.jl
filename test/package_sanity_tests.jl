
using Aqua

@testset "Code quality" begin
    Aqua.test_all(IteratorSampling, ambiguities = false)
end