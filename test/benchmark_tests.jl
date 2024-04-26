@testset "benchmarks" begin
    rng = Xoshiro(42)
    iter = Iterators.filter(x -> x != 10, 1:10^4)
    wv(el) = 1.0
    for m in (algR, algL, algRSWRSKIP)
        for size in (1, 10)
            size == 1 && m === algRSWRSKIP && continue
            s = size == 1 ? () : (10,)
            b = @benchmark itsample($rng, $iter, $s..., $m) evals=1
            mstr = "$m $(size == 1 ? :single : :multi)"
            print(mstr * repeat(" ", 35-length(mstr)))
            print(" --> Time: $(@sprintf("%.2f", median(b.times)*1e-3)) μs |")
            println(" Memory: $(b.memory) bytes")
        end
    end
    for m in (algARes, algAExpJ, algWRSWRSKIP)
        for size in (1, 10)
            size == 1 && m === algWRSWRSKIP && continue
            s = size == 1 ? () : (10,)
            b = @benchmark itsample($rng, $iter, $wv, $s..., $m) evals=1
            mstr = "$m $(size == 1 ? :single : :multi)"
            print(mstr * repeat(" ", 35-length(mstr)))
            print(" --> Time: $(@sprintf("%.2f", median(b.times)*1e-3)) μs |")
            println(" Memory: $(b.memory) bytes")
        end
    end
end
