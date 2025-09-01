
using StreamSampling
using StatsBase, Random, ChunkSplitters, ThreadPinning
using Arrow

pinthreads(:compact)

const dtype = @NamedTuple{a::Float64, b::Float64, c::Float64, d::Float64}
const totaltpl = 10^11÷32 #100GB!
const chunktpl = totaltpl ÷ 100
const numchunks = ceil(Int, totaltpl / chunktpl)

function generate_file(filename)
    for i in 1:numchunks
        starttpl, endtpl = (i-1)*chunktpl+1, min(i*chunktpl, totaltpl)
          Arrow.append("random_data.arrow", (data=map(i -> (a=rand(), b=rand(), c=rand(), d=rand()), 
                                             1:endtpl-starttpl+1),);file=false)
    end
end

function sample_file_pop(data, rng, n)
    samples = Vector{dtype}[]
    weights = Float64[]
    for i in 1:numchunks
        starttpl, endtpl = (i-1)*chunktpl+1, min(i*chunktpl, totaltpl)
        data_chunk = data[starttpl:endtpl]
        ws = [d[end] for d in data_chunk]
        Wtot = sum(ws)
        s = sample(rng, data_chunk, Weights(ws, Wtot), n)
        push!(samples, s)
        push!(weights, Wtot)
        if length(samples) == 10
        	samples = [combine(rng, samples, weights),]
        	weights = [sum(weights),]
        end
    end
    return combine(rng, samples, weights)
end
function psample_file_pop(data, rngs, n)
    samples = Vector{dtype}[]
    weights = Float64[]
    rlock = ReentrantLock()
    Threads.@threads for (j,c) in enumerate(chunks(1:numchunks, n=Threads.nthreads()))
    	for i in c
	        starttpl, endtpl = (i-1)*chunktpl+1, min(i*chunktpl, totaltpl)
	        data_chunk = data[starttpl:endtpl]
	        ws = [d[end] for d in data_chunk]
	        Wtot = sum(ws)
	        s = sample(rngs[j], data_chunk, Weights(ws, Wtot), n)
	        @lock rlock begin
		        push!(samples, s)
		        push!(weights, Wtot)
		        if length(samples) == 10
		        	samples = [combine(rngs[j], samples, weights),]
		        	weights = [sum(weights),]
		        end
	    	end
	    end
    end
    return combine(rngs[1], samples, weights)
end

function sample_file_rs(data, rng, n, alg)
    rs = ReservoirSampler{dtype}(rng, n, alg)
    @inbounds for i in 1:length(data)
    	d = data[i]
        fit!(rs, d, d[end])
    end
    return value(rs)
end
function psample_file_rs(data, rngs, n, alg)
    rsv = [ReservoirSampler{dtype}(rngs[i], n, alg) for i in 1:Threads.nthreads()]
    Threads.@threads for (i,c) in enumerate(chunks(1:length(data), n=Threads.nthreads()))
        @inbounds for j in c
        	d = data[j]
            fit!(rsv[i], d, d[end])
        end
    end
    return value(merge!(rsv...))
end

wf(d) = d[end]
function sample_file_st(data, rng, n, alg)
    W = sum(x[end] for x in data)
    s = Vector{dtype}(undef, n)
    @inbounds for (i, d) in enumerate(StreamSampler{dtype}(rng, data, wf, n, W, alg))
        s[i] = d
    end
    return s
end
function psample_file_st(data, rngs, n, alg)
    samples = Vector{Vector{dtype}}(undef, Threads.nthreads())
    weights = Vector{Float64}(undef, Threads.nthreads())
    Threads.@threads for (i,c) in enumerate(chunks(1:length(data), n=Threads.nthreads()))
        W = sum((@inbounds data[j][end]) for j in c)
        st_data = ((@inbounds data[j]) for j in c)
        samples[i] = collect(StreamSampler{dtype}(rngs[i], @view(data[c]), wf, n, W, alg))
        weights[i] = W
    end
    return combine(rngs[1], samples, weights)
end

filename = "random_data.arrow"

!isfile(filename) && generate_file(filename)

n = totaltpl ÷ 1000
rng = Xoshiro(42)
rngs = [Xoshiro(i) for i in 1:Threads.nthreads()]
data = Arrow.Table(filename).data

precompile(sample_file_pop, typeof.((data, rng, n)))
precompile(psample_file_pop, typeof.((data, rngs, n)))
precompile(sample_file_rs, typeof.((data, rng, n, AlgWRSWRSKIP())))
precompile(psample_file_rs, typeof.((data, rngs, n, AlgWRSWRSKIP())))
precompile(sample_file_st, typeof.((data, rng, n, AlgORDWSWR())))
precompile(psample_file_st, typeof.((data, rngs, n, AlgORDWSWR())))

times = []
for n in (totaltpl ÷ 100000, totaltpl ÷ 10000, totaltpl ÷ 1000)
    t1 = @elapsed sample_file_pop(data, rng, n);
    t2 = @elapsed psample_file_pop(data, rngs, n);

    t3 = @elapsed sample_file_st(data, rng, n, AlgORDWSWR());
    t4 = @elapsed psample_file_st(data, rngs, n, AlgORDWSWR());

    t5 = @elapsed sample_file_rs(data, rng, n, AlgWRSWRSKIP());
    t6 = @elapsed psample_file_rs(data, rngs, n, AlgWRSWRSKIP());

    push!(times, [t1, t2, t3, t4, t5, t6])
end
times = hcat(times...) 

using CairoMakie

x = 1:3
xtick_positions = [1,2,3]
xtick_labels = ["0.001%","0.01%","0.1%"]

algonames = ["chunks", "chunks (4 threads)", "stream", "stream (4 threads)",
             "reservoir", "reservoir (4 threads)",]
markers = [:circle, :rect, :utriangle, :hexagon, :diamond, :xcross]

fig = Figure();
ax = Axis(fig[1, 1]; xlabel = "sample size", ylabel = "time (s)", 
          title = "Sampling Performance on Persistent Data",
          xticks = (xtick_positions, xtick_labels), 
          xgridstyle = :dot, ygridstyle = :dot,
          xticklabelsize = 10, yticklabelsize = 10,
          xlabelsize = 12, ylabelsize = 12,
)

for i in 1:size(times, 1)
    scatterlines!(ax, x, times[i, :];
                  label = algonames[i],
                  linestyle = (:dash, :dense),
                  marker = markers[i],
                  markersize = 8,
                  linewidth = 2)
end


fig[2, 1] = Legend(fig, ax, framevisible = false, orientation = :horizontal, 
                   halign = :center, nbanks=2, fontsize=10)

fig
save("comparison_ondisk_algs.pdf", fig)
