@testset "benchmarks" begin
    rng = Xoshiro(42)
    iter = Iterators.filter(x -> x != 10, 1:10^2)
    wv(el) = 1.0
    for m in (AlgR(), AlgL(), AlgRSWRSKIP())
        for size in (nothing, 10)
            size == nothing && m === AlgL() && continue
            size == nothing && m === AlgRSWRSKIP() && continue
            s = size == nothing ? () : (size,)
            b = @benchmark itsample($rng, $iter, $s..., $m) evals=1
            mstr = "$m $(size == nothing ? :single : :multi)"
            print(mstr * repeat(" ", 35-length(mstr)))
            print(" --> Time: $(median(b.times)) ns |")
            println(" Memory: $(b.memory) bytes")
        end
    end
    for m in (AlgARes(), AlgAExpJ(), AlgWRSWRSKIP())
        for size in (nothing, 10)
            size == nothing && m === AlgARes() && continue
            size == nothing && m === AlgWRSWRSKIP() && continue
            s = size == nothing ? () : (size,)
            b = @benchmark itsample($rng, $iter, $wv, $s..., $m) evals=1
            mstr = "$m $(size == nothing ? :single : :multi)"
            print(mstr * repeat(" ", 35-length(mstr)))
            print(" --> Time: $(median(b.times)) ns |")
            println(" Memory: $(b.memory) bytes")
        end
    end
end
