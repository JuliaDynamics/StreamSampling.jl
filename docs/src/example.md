
# An Illustrative Example

Suppose to receive data about some process in the form of a stream and you want
to detect if anything is going wrong in the data being received. A reservoir 
sampling approach could be useful to evaluate properties on the data stream. 
This is a demonstration of such a use case using `StreamSampling.jl`. We will
assume that the monitored statistic in this case is the mean of the data, and 
you want that to be lower than a certain threshold otherwise some malfunctioning
is expected.

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
