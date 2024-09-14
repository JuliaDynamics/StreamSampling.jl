
using PrecompileTools

@setup_workload let
    iter = Iterators.filter(x -> x != 10, 1:20);
    wv(el) = 1.0
    update_s_no_weights!(rs, iter) = for x in iter update!(rs, x) end
    update_s!(rs, iter) = for x in iter update!(rs, x, wv(x)) end
    @compile_workload let
        rs = ReservoirSample(Int, AlgR())
        update_s_no_weights!(rs, iter)
        rs = ReservoirSample(Int, AlgAExpJ())
        update_s!(rs, iter)
        rs = ReservoirSample(Int, 2, AlgR())
        update_s_no_weights!(rs, iter)
        rs = ReservoirSample(Int, 2, AlgL())
        update_s_no_weights!(rs, iter)
        rs = ReservoirSample(Int, 2, AlgRSWRSKIP())
        update_s_no_weights!(rs, iter)
        rs = ReservoirSample(Int, 2, AlgARes())
        update_s!(rs, iter)
        rs = ReservoirSample(Int, 2, AlgAExpJ())
        update_s!(rs, iter)
        rs = ReservoirSample(Int, 2, AlgWRSWRSKIP())
        update_s!(rs, iter)
    end
end
