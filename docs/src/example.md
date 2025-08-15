
# Some Applications

## Sampling from Data on Disk

Suppose we want to sample from large datasets stored on disk. `StreamSampling.jl`
is very suited for this task. Let's simulate this task by generating some data in 
HDF5 and arrow formats and batch sampling them. You will need 20GB of space on disk
for running this example. If not available you can set a smaller size for `totaltpl`.

We first generate the datasets and store them with


```julia
using StreamSampling, Random, ChunkSplitters
using HDF5, Arrow

const dtype = @NamedTuple{a::Float64, b::Float64, c::Float64, d::Float64}
const totaltpl = 10^10÷32
const chunktpl = 5*10^5
const numchunks = ceil(Int, totaltpl / chunktpl)

function generate_file(filename, format)
    if format == :hdf5
        h5open(filename, "w") do file
            dset = create_dataset(file, "data", dtype, (totaltpl,), chunk=(chunktpl,))
            Threads.@threads for i in 1:numchunks
                starttpl, endtpl = (i-1)*chunktpl+1, min(i*chunktpl, totaltpl)
                dset[starttpl:endtpl] = map(i -> (a=rand(), b=rand(), c=rand(), d=rand()), 
                                            1:endtpl-starttpl+1)
            end
        end
    elseif format == :arrow
        for i in 1:numchunks
            starttpl, endtpl = (i-1)*chunktpl+1, min(i*chunktpl, totaltpl)
            Arrow.append("random_data.arrow", (data=map(i -> (a=rand(), b=rand(), c=rand(), d=rand()), 
                                               1:endtpl-starttpl+1),);file=false)
        end
    end
end

!isfile("random_data.h5") && generate_file("random_data.h5", :hdf5)
!isfile("random_data.arrow") && generate_file("random_data.arrow", :arrow)
```

Then we can sample them using 1 thread with

```julia
function sample_file(filename, rng, n, alg, format)
    rs = ReservoirSampler{dtype}(rng, n, alg)
    if format == :hdf5
        h5open(filename, "r") do file
            dset = file["data"]
            for i in 1:numchunks
                starttpl, endtpl = (i-1)*chunktpl+1, min(i*chunktpl, totaltpl)
                data_chunk = dset[starttpl:endtpl]
                for d in data_chunk
                    fit!(rs, d)
                end
            end
        end
    elseif format == :arrow
        rs = ReservoirSampler{dtype}(rng, n, alg)
        data = Arrow.Table(filename).data
        @inbounds for i in 1:length(data)
            fit!(rs, data[i])
        end
    end
    return rs
end

rng = Xoshiro(42)
@time rs = sample_file("random_data.h5", rng, 10^7, AlgRSWRSKIP(), :hdf5)
```
```julia
 43.514238 seconds (937.21 M allocations: 42.502 GiB, 2.57% gc time)
```
```julia
@time rs = sample_file("random_data.arrow", rng, 10^7, AlgRSWRSKIP(), :arrow)
```
```julia
 38.635389 seconds (1.25 G allocations: 33.500 GiB, 3.52% gc time, 75763 lock conflicts)
```

We can try to improve the performance by using multiple threads. Here, I started Julia
with `julia -t4 --gcthreads=4,1` on my machine

```julia
function psample_file(filename, rngs, n, alg, format)
    rsv = [ReservoirSampler{dtype}(rngs[i], n, alg) for i in 1:Threads.nthreads()]
    if format == :hdf5
        h5open(filename, "r") do file
            dset = file["data"]
            for c in chunks(1:numchunks; n=ceil(Int, numchunks/Threads.nthreads()))
                Threads.@threads for (j, i) in collect(enumerate(c))
                    starttpl, endtpl = (i-1)*chunktpl+1, min(i*chunktpl, totaltpl)
                    data_chunk, rs = dset[starttpl:endtpl], rsv[j]
                    for d in data_chunk
                        fit!(rs, d)
                    end
                end
            end
        end
    elseif format == :arrow
        data = Arrow.Table(filename).data
        Threads.@threads for (i,c) in enumerate(chunks(1:length(data), n=Threads.nthreads()))
            @inbounds for j in c
                fit!(rsv[i], data[j])
            end
        end
    end
    return merge(rsv...)
end

rngs = [Xoshiro(i) for i in 1:Threads.nthreads()]
@time rs = psample_file("random_data.h5", rngs, 10^7, AlgRSWRSKIP(), :hdf5)
```
```julia
 23.240628 seconds (937.23 M allocations: 45.185 GiB, 9.52% gc time, 9375 lock conflicts)
```
```julia
@time rs = psample_file("random_data.arrow", rngs, 10^7, AlgRSWRSKIP(), :arrow)
```
```julia
 5.868995 seconds (175.91 k allocations: 3.288 GiB, 6.44% gc time, 64714 lock conflicts)
```

As you can see, the speed-up is not linear in the number of threads for an hdf5 file. This is
mainly due to the fact that accessing the chunks is single-threaded, so one would need to use
`MPI.jl` as  explained at [HDF5.jl/stable/mpi/](https://juliaio.github.io/HDF5.jl/stable/mpi/) to
improve the multi-threading performance. Though, we are already sampling at 500MB/s, which is not bad!
Using `Arrow.jl` gives an even better performance, and a scalability which is better than
linear somehow, reaching a 2GB/s sampling speed!

## Monitoring

Suppose to receive data about some process in the form of a stream and you want
to detect if anything is going wrong in the data being received. A reservoir 
sampling approach could be useful to evaluate properties on the data stream. 
This is a demonstration of such a use case using `StreamSampling.jl`. We will
assume that the monitored statistic in this case is the mean of the data, and 
you want that to be lower than a certain threshold otherwise some malfunctioning
is expected

```julia
using StreamSampling, Statistics, Random

function monitor(stream, thr)
    rng = Xoshiro(42)
    # we use a reservoir sample of 10^4 elements
    rs = ReservoirSampler{Int}(rng, 10^4)
    # we loop over the stream and fit the data in the reservoir
    for (i, e) in enumerate(stream)
        fit!(rs, e)
        # we check the mean value every 1000 iterations
        if iszero(mod(i, 1000)) && mean(value(rs)) >= thr
            return rs
        end
    end
end
```

We use some toy data for illustration

```julia
stream = 1:10^8; # the data stream
thr = 2*10^7; # the threshold for the mean monitoring
```

Then, we run the monitoring

```julia
rs = monitor(stream, thr);
```

The number of observations until the detection is triggered is
given by

```julia
nobs(rs)
```

which is very close to the true value of `4*10^7 - 1` observations.

Note that in this case we could use an online mean methods, 
instead of holding all the sample into memory. However, 
the approach with the sample is more general because it
allows to estimate any statistic about the stream. 
