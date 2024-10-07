# Suppose to receive data about some process in the form of a stream and you want
# to detect if anything is going wrong in the data being received. A reservoir 
# sampling approach  be useful to evaluate properties on the data stream. 
# We will assume that the sufficient statistic in this case is the mean of
# the data, and you want that to be lower than a certain threshold otherwise
# some malfunctioning is expected. This is a demonstration of such a use case
# using StreamSampling.jl

using StreamSampling, Statistics, Random

function monitor(stream, thr)
	rng = Xoshiro(42)
	# we use a reservoir sample of 10^4 elements
	rs = ReservoirSample(rng, Int, 10^4)
	# we loop over the stream and fit the data in the reservoir
	for (i, e) in enumerate(stream)
		fit!(rs, e)
		# we check the mean value every 1000 iterations
		if iszero(mod(i, 1000)) && mean(value(rs)) >= thr
			return rs
		end
	end
end

# the data stream in this toy example
stream = 1:10^8

# the threshold for the mean monitoring
thr = 2*10^7

# the true number of observations at which the threshold is reached
true_nobs = 4*10^7 - 1

# the detection error is less than 0.03%
rs = monitor(stream, thr)
println(nobs(rs)/true_nobs)

# Note that in this case we could use an online mean methods, 
# instead of holding all the sample. However, the approach with
# the sample is more general because it allows to estimate any
# statistics about the stream. 
