
# this requires downloading the clickstream-enwiki-2024-12.tsv file
# from https://dumps.wikimedia.org/other/clickstream/2024-12/

function construct_data(filename)
    data = Tuple{UInt, Int}[]
    open(filename) do io
        for line in eachline(io)
            fields = split(line, '\t')
            if fields[2] != "Main_Page" && fields[2] != "Hyphen-minus"
                push!(data, (hash(fields[2]), parse(Int, fields[4])))
            end
        end
    end
    return data
end

function setup_add(rng, T, k, alg)
    return ReservoirSampler{T}(rng, k, alg)
end

function benchmark_add(r, s)
    @inbounds for x in s
        add!(r, x, Float64(last(x)))
    end
    return r
end

function setup_get(rng, T, k, alg, s)
    r = ReservoirSampler{T}(rng, k, alg)
    for x in s
        add!(r, x, Float64(last(x)))
    end
    return r
end

function benchmark_get(r)
    return get(r)
end

rng = Xoshiro(42)
data = construct_data("clickstream-enwiki-2024-12.tsv")

results = DataFrame(alg=String[], N=Int[], m=Int[],
                    repetitions=Int[], t_add=Float64[], 
                    t_get=Float64[])

dict_names = Dict(AlgWRSWRBIN => "WRSWR-BIN", AlgWRAExpJ => "WRAExp-J", AlgWRSWRSKIP => "WRSWR-SKIP")

ks = ceil.(Int, length(data) .* [10, 1, 0.1, 0.01] ./ 100)
for alg in [AlgWRSWRBIN, AlgWRAExpJ, AlgWRSWRSKIP]
    for k in ks
        b = @be setup_add(rng, Tuple{UInt,Int}, k, alg()) benchmark_add(_, $data) seconds=500 samples=100 evals=1
        samples = b.samples
        time_add = 10^9 * (sum(s.time for s in samples) / length(samples)) / length(data)
        b2 = @be setup_get(rng, Tuple{UInt,Int}, k, alg(), data) benchmark_get(_) seconds=500 samples=1 evals=100
        samples2 = b2.samples
        time_get = 10^9 * (sum(s.time for s in samples2) / length(samples2))
        @assert length(samples) == 100
        push!(results, (dict_names[alg], length(data), k, 100, time_add, time_get))
    end
end

CSV.write("benchmark_data_results.csv", results; writeheader=true)
