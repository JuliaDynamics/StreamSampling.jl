
@testset "benchmarks" begin
	rng = Xoshiro(42)
	iter = Iterators.filter(x -> x != 10, 1:10^4)
	wv(el) = 1.0
	for m in (algR, algL, algRSWRSKIP)
		b = @benchmark itsample($rng, $iter, 10, $m) evals=1
		println("Method $m")
		println("  Time: $(round(median(b.times)*1e-3, digits=2)) μs")
		println("  Memory: $(b.memory) bytes")
	end
	for m in (algARes, algAExpJ, algWRSWRSKIP)
		b = @benchmark itsample($rng, $iter, $wv, 10, $m) evals=1
		println("Method $m")
		println("  Time: $(round(median(b.times)*1e-3, digits=2)) μs")
		println("  Memory: $(b.memory) bytes")
	end
end
