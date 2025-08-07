
using PrecompileTools

@setup_workload let
    iter = Iterators.filter(x -> x != 10, 1:20);
    wv(el) = 1.0
    update_s!(rs, iter) = for x in iter fit!(rs, x) end
    update_s!(rs, iter, wv) = for x in iter fit!(rs, x, wv(x)) end
    @compile_workload let
        rs = ReservoirSampler{Int}(AlgRSWRSKIP())
        update_s!(rs, iter)
        rs = ReservoirSampler{Int}(AlgWRSWRSKIP())
        update_s!(rs, iter, wv)
        rs = ReservoirSampler{Int}(2, AlgR())
        update_s!(rs, iter)
        rs = ReservoirSampler{Int}(2, AlgL())
        update_s!(rs, iter)
        rs = ReservoirSampler{Int}(2, AlgRSWRSKIP())
        update_s!(rs, iter)
        rs = ReservoirSampler{Int}(2, AlgARes())
        update_s!(rs, iter, wv)
        rs = ReservoirSampler{Int}(2, AlgAExpJ())
        update_s!(rs, iter, wv)
        rs = ReservoirSampler{Int}(2, AlgWRSWRSKIP())
        update_s!(rs, iter, wv)
    end
end
