
# Illustrative Examples

## Sampling from Data on Disk

Suppose we want to sample from large datasets stored on disk. `StreamSampling.jl`
is very suited for this task. Let's simulate this task by generating some data in 
HDF5 format and batch sampling them. You will need 10GB of space on disk for running
this example. If not available you can set a smaller size for `totaltuples`.

We first generate the dataset and store it with

```julia
using StreamSampling, Random, ChunkSplitters, HDF5

const dtype = @NamedTuple{a::Float64, b::Float64, c::Float64, d::Float64}
const totaltuples = 10^10÷32
const chunktuples = 5*10^5
const numchunks = ceil(Int, totaltuples / chunktuples)

function generate_large_hdf5_file(filename)
    h5open(filename, "w") do file
        dset = create_dataset(file, "data", dtype, (totaltuples,), chunk=(chunktuples,))
        Threads.@threads for i in 1:numchunks
            startrow, endrow = (i-1)*chunktuples+1, min(i*chunktuples, totaltuples)
            dset[startrow:endrow] = map(i -> (a=rand(), b=rand(), c=rand(), d=rand()), 
                                        1:endrow-startrow+1)
        end
    end
end

!isfile("large_random_data.h5") && generate_large_hdf5_file("large_random_data.h5")
```

Then we can sample it using 1 thread with

```julia
function sample_large_hdf5_file(filename, rng, n, alg)
    rs = ReservoirSampler{dtype}(rng, n, alg)
    h5open(filename, "r") do file
        dset = file["data"]
        for i in 1:numchunks
            startrow, endrow = (i-1)*chunktuples+1, min(i*chunktuples, totaltuples)
            data_chunk = dset[startrow:endrow]
            for d in data_chunk
                fit!(rs, d)
            end
        end
    end
    return rs
end

rng = Xoshiro(42)
@time rs = sample_large_hdf5_file("large_random_data.h5", rng, 10^7, AlgRSWRSKIP())
```
```julia
 43.514238 seconds (937.21 M allocations: 42.502 GiB, 2.57% gc time)
```

We can try to improve the performance by using multiple threads. Here, I started Julia
with `julia -t6 --gcthreads=6,1` on my machine

```julia
function psample_large_hdf5_file(filename, rngs, n, alg)
    rsv = [ReservoirSampler{dtype}(rngs[i], n, alg) for i in 1:Threads.nthreads()]
    h5open(filename, "r") do file
        dset = file["data"]
        for c in chunks(1:numchunks; n=ceil(Int, numchunks/Threads.nthreads()))
            Threads.@threads for (j, i) in collect(enumerate(c))
                startrow, endrow = (i-1)*chunktuples+1, min(i*chunktuples, totaltuples)
                data_chunk, rs = dset[startrow:endrow], rsv[j]
                for d in data_chunk
                    fit!(rs, d)
                end
            end
        end
    end
    return merge(rsv...)
end

rngs = [Xoshiro(i) for i in 1:Threads.nthreads()]
@time rs = psample_large_hdf5_file("large_random_data.h5", rngs, 10^7, AlgRSWRSKIP())
```
```julia
 21.545665 seconds (937.21 M allocations: 46.525 GiB, 9.50% gc time, 14913 lock conflicts)
```

As you can see, the speed-up is not linear in the number of threads. This is mainly due to
the fact that accessing the chunks is single-threaded, so one would need to use `MPI.jl` as 
explained at [https://juliaio.github.io/HDF5.jl/stable/mpi/](https://juliaio.github.io/HDF5.jl/stable/mpi/) 
to improve the multi-threading performance. Though, we are already sampling at 500MB/S, which is not bad!

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
