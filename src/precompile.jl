
using PrecompileTools

@setup_workload begin
    @compile_workload begin
        iter = Iterators.filter(x -> x != 10, 1:20);
        wv(el) = 1.0
        rs = ReservoirSample(Int, algARes)
        for x in iter update!(rs, x, wv(x)) end
        rs = ReservoirSample(Int, algAExpJ)
        for x in iter update!(rs, x, wv(x)) end
        rs = ReservoirSample(Int, 2, algARes)
        for x in iter update!(rs, x, wv(x)) end
        rs = ReservoirSample(Int, 2, algAExpJ)
        for x in iter update!(rs, x, wv(x)) end
        rs = ReservoirSample(Int, 2, algWRSWRSKIP)
        for x in iter update!(rs, x, wv(x)) end
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
