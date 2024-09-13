
using PrecompileTools

@setup_workload let
    iter = Iterators.filter(x -> x != 10, 1:20);
    wv(el) = 1.0
    update_s_no_weights!(rs, iter) = for x in iter update!(rs, x) end
    update_s!(rs, iter) = for x in iter update!(rs, x, wv(x)) end
    @compile_workload let
        rs = ReservoirSample(Int, algR)
        update_s_no_weights!(rs, iter)
        rs = ReservoirSample(Int, algL)
        update_s_no_weights!(rs, iter)
        rs = ReservoirSample(Int, algARes)
        update_s!(rs, iter)
        rs = ReservoirSample(Int, algAExpJ)
        update_s!(rs, iter)
        rs = ReservoirSample(Int, 2, algR)
        update_s_no_weights!(rs, iter)
        rs = ReservoirSample(Int, 2, algL)
        update_s_no_weights!(rs, iter)
        rs = ReservoirSample(Int, 2, algRSWRSKIP)
        update_s_no_weights!(rs, iter)
        rs = ReservoirSample(Int, 2, algARes)
        update_s!(rs, iter)
        rs = ReservoirSample(Int, 2, algAExpJ)
        update_s!(rs, iter)
        rs = ReservoirSample(Int, 2, algWRSWRSKIP)
        update_s!(rs, iter)
    end
end
