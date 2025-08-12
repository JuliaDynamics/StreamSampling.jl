
using PrecompileTools

@setup_workload let
    iter = Iterators.filter(x -> x != 10, 1:20);
    @compile_workload let
        for alg in (AlgRSWRSKIP(),)
            rs = ReservoirSampler{Int}(alg)
            for x in iter fit!(rs, x) end
        end
        for alg in (AlgR(), AlgL(), AlgRSWRSKIP())
            rs = ReservoirSampler{Int}(2, alg)
            for x in iter fit!(rs, x) end
        end
        for alg in (AlgWRSWRSKIP(),)
            rs = ReservoirSampler{Int}(alg)
            for x in iter fit!(rs, x, 1.0) end
        end
        for alg in (AlgARes(), AlgAExpJ(), AlgWRSWRSKIP())
            rs = ReservoirSampler{Int}(2, alg)
            for x in iter fit!(rs, x, 1.0) end
        end
    end
end
