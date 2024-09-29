@testset "benchmarks" begin
    rng = Xoshiro(42)
    iter_no_f = (x for x in 1:10^2)
    iter = Iterators.filter(x -> x != 10, 1:10^2)
    wv(el) = 1.0
    for m in (:AlgS, AlgR(), AlgL(), AlgRSWRSKIP())
        for size in (nothing, 10)
            size == nothing && m === AlgL() && continue
            size == nothing && m === AlgR() && continue
            s = size == nothing ? () : (size,)
            b = @benchmark itsample($rng, $(m === :AlgS ? iter_no_f : iter), $s..., $m) evals=1
            mstr = "$m $(size == nothing ? :single : :multi)"
            print(mstr * repeat(" ", 35-length(mstr)))
            print(" --> Time: $(median(b.times)) ns |")
            println(" Memory: $(b.memory) bytes")
        end
    end
    for m in (AlgARes(), AlgAExpJ(), AlgWRSWRSKIP())
        for size in (nothing, 10)
            size == nothing && m === AlgARes() && continue
            size == nothing && m === AlgAExpJ() && continue
            s = size == nothing ? () : (size,)
            b = @benchmark itsample($rng, $iter, $wv, $s..., $m) evals=1
            mstr = "$m $(size == nothing ? :single : :multi)"
            print(mstr * repeat(" ", 35-length(mstr)))
            print(" --> Time: $(median(b.times)) ns |")
            println(" Memory: $(b.memory) bytes")
        end
    end
end
