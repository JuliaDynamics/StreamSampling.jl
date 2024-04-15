
using Aqua

@testset "Code quality" begin
    Aqua.test_all(StreamSampling, ambiguities = false)
end
