
function setup_add(rng, T, k, alg)
    return ReservoirSampler{T}(rng, k, alg)
end

function benchmark_add(r, n, weights)
	@inbounds for i in 1:n
        add!(r, i, weights[i])
    end
	return r
end

function setup_get(rng, T, k, alg, n, f)
    r = ReservoirSampler{T}(rng, k, alg)
    for i in 1:n
        add!(r, i, f(i))
    end
    return r
end

function benchmark_get(r)
    return get(r)
end

results = DataFrame(alg=String[], N=Int[], m=Int[],
                    d=String[], repetitions=Int[], t_add=Float64[], 
                    t_get=Float64[])

d_incr(i) = Float64(i)
d_decr(i) = 1.0/Float64(i)
d_const(i) = 1.0

rng = Xoshiro(42)
p = 7
n = 10^p

dict_names = Dict(AlgWRSWRBIN => "WRSWR-BIN", AlgWRAExpJ => "WRAExp-J", AlgWRSWRSKIP => "WRSWR-SKIP")
for f in [d_decr, d_const, d_incr]
    weights = f.(1:n)
    for alg in [AlgWRSWRBIN, AlgWRAExpJ, AlgWRSWRSKIP]
        for k in [10^i for i in 3:p-1]
        	b = @be setup_add(rng, Int, k, alg()) benchmark_add(_, $n, $weights) seconds=200 samples=100 evals=1
            samples = b.samples
            time_add = 10^9 * (sum(s.time for s in samples) / length(samples)) / n
            b2 = @be setup_get(rng, Int, k, alg(), n, f) benchmark_get(_) seconds=200 samples=1 evals=100
            samples2 = b2.samples
            time_get = 10^9 * (sum(s.time for s in samples2) / length(samples2))
            @assert length(samples) == 100
            push!(results, (dict_names[alg], n, k, string(f), 100, time_add, time_get))
        end
    end
end

CSV.write("benchmark_results.csv", results; writeheader=true)
