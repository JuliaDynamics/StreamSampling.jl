
using PrecompileTools

@setup_workload begin
    iter = Iterators.filter(x -> x != 10, 1:20);
    wv(el) = 1.0
    update_s!(rs, iter) = for x in iter update!(rs, x, wv(x)) end
    @compile_workload begin
        rs = ReservoirSample(Int, algARes)
        update_s!(rs, iter)
        rs = ReservoirSample(Int, algAExpJ)
        update_s!(rs, iter)
        rs = ReservoirSample(Int, 2, algARes)
        update_s!(rs, iter)
        rs = ReservoirSample(Int, 2, algAExpJ)
        update_s!(rs, iter)
        rs = ReservoirSample(Int, 2, algWRSWRSKIP)
        update_s!(rs, iter)
        itsample(iter, algR)
        itsample(iter, algL)
        itsample(iter, 2, algR)
        itsample(iter, 2, algL)
        itsample(iter, 2, algRSWRSKIP)
        itsample(iter, wv, algARes)
        itsample(iter, wv, algAExpJ)
        itsample(iter, wv, 2, algARes)
        itsample(iter, wv, 2, algAExpJ)
        itsample(iter, wv, 2, algWRSWRSKIP)
    end
end
