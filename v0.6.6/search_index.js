var documenterSearchIndex = {"docs":
[{"location":"api/#API","page":"API","title":"API","text":"","category":"section"},{"location":"api/","page":"API","title":"API","text":"This is the API page of the package. For a general overview of the functionalities  consult the ReadMe.","category":"page"},{"location":"api/#General-Functionalities","page":"API","title":"General Functionalities","text":"","category":"section"},{"location":"api/","page":"API","title":"API","text":"ReservoirSample\nfit!\nmerge!\nmerge\nempty!\nvalue\nordvalue\nnobs\nStreamSample\nitsample","category":"page"},{"location":"api/#StreamSampling.ReservoirSample","page":"API","title":"StreamSampling.ReservoirSample","text":"ReservoirSample{T}([rng], method = AlgRSWRSKIP())\nReservoirSample{T}([rng], n::Int, method = AlgL(); ordered = false)\n\nInitializes a reservoir sample which can then be fitted with fit!. The first signature represents a sample where only a single element is collected. If ordered is true, the reservoir sample values can be retrived in the order they were collected with ordvalue.\n\nLook at the Sampling Algorithms section for the supported methods. \n\n\n\n\n\n","category":"type"},{"location":"api/#StatsAPI.fit!","page":"API","title":"StatsAPI.fit!","text":"fit!(rs::AbstractReservoirSample, el)\nfit!(rs::AbstractReservoirSample, el, w)\n\nUpdates the reservoir sample by taking into account the element passed. If the sampling is weighted also the weight of the elements needs to be passed.\n\n\n\n\n\n","category":"function"},{"location":"api/#Base.merge!","page":"API","title":"Base.merge!","text":"Base.merge!(rs::AbstractReservoirSample, rs::AbstractReservoirSample...)\n\nUpdates the first reservoir sample by merging its value with the values of the other samples. Currently only supported for samples with replacement.\n\n\n\n\n\n","category":"function"},{"location":"api/#Base.merge","page":"API","title":"Base.merge","text":"Base.merge(rs::AbstractReservoirSample...)\n\nCreates a new reservoir sample by merging the values of the samples passed. Currently only supported for sample with replacement.\n\n\n\n\n\n","category":"function"},{"location":"api/#Base.empty!","page":"API","title":"Base.empty!","text":"Base.empty!(rs::AbstractReservoirSample)\n\nResets the reservoir sample to its initial state.  Useful to avoid allocating a new sample in some cases.\n\n\n\n\n\n","category":"function"},{"location":"api/#OnlineStatsBase.value","page":"API","title":"OnlineStatsBase.value","text":"value(rs::AbstractReservoirSample)\n\nReturns the elements collected in the sample at the current  sampling stage.\n\nNote that even if the sampling respects the schema it is assigned when ReservoirSample is instantiated, some ordering in  the sample can be more probable than others. To represent each one  with the same probability call shuffle! over the result.\n\n\n\n\n\n","category":"function"},{"location":"api/#StreamSampling.ordvalue","page":"API","title":"StreamSampling.ordvalue","text":"ordvalue(rs::AbstractReservoirSample)\n\nReturns the elements collected in the sample at the current  sampling stage in the order they were collected. This applies only when ordered = true is passed in ReservoirSample.\n\n\n\n\n\n","category":"function"},{"location":"api/#StatsAPI.nobs","page":"API","title":"StatsAPI.nobs","text":"nobs(rs::AbstractReservoirSample)\n\nReturns the total number of elements that have been observed so far  during the sampling process.\n\n\n\n\n\n","category":"function"},{"location":"api/#StreamSampling.StreamSample","page":"API","title":"StreamSampling.StreamSample","text":"StreamSample{T}([rng], iter, n, [N], method = AlgD())\n\nInitializes a stream sample, which can then be iterated over to return the sampling elements of the iterable iter which is assumed to have a eltype of T. The methods implemented in StreamSample require the knowledge of the total number of elements in the stream N, if not provided it is assumed to be available by calling length(iter).\n\n\n\n\n\n","category":"type"},{"location":"api/#StreamSampling.itsample","page":"API","title":"StreamSampling.itsample","text":"itsample([rng], iter, method = AlgRSWRSKIP())\nitsample([rng], iter, wfunc, method = AlgWRSWRSKIP())\n\nReturn a random element of the iterator, optionally specifying a rng  (which defaults to Random.default_rng()) and a function wfunc which accept each element as input and outputs the corresponding weight. If the iterator is empty, it returns nothing.\n\n\n\nitsample([rng], iter, n::Int, method = AlgL(); ordered = false)\nitsample([rng], iter, wfunc, n::Int, method = AlgAExpJ(); ordered = false)\n\nReturn a vector of n random elements of the iterator,  optionally specifying a rng (which defaults to Random.default_rng()) a weight function wfunc and a method. ordered dictates whether an  ordered sample (also called a sequential sample, i.e. a sample where items  appear in the same order as in iter) must be collected.\n\nIf the iterator has less than n elements, in the case of sampling without replacement, it returns a vector of those elements.\n\n\n\nitsample(rngs, iters, n::Int)\nitsample(rngs, iters, wfuncs, n::Int)\n\nParallel implementation which returns a sample with replacement of size n from the multiple iterables. All the arguments except from n must be tuples.\n\n\n\n\n\n","category":"function"},{"location":"api/#Sampling-Algorithms","page":"API","title":"Sampling Algorithms","text":"","category":"section"},{"location":"api/","page":"API","title":"API","text":"AlgR\nAlgL\nAlgRSWRSKIP\nAlgARes\nAlgAExpJ\nAlgWRSWRSKIP\nAlgD\nAlgORDSWR","category":"page"},{"location":"api/#StreamSampling.AlgR","page":"API","title":"StreamSampling.AlgR","text":"Implements random reservoir sampling without replacement. To be used with ReservoirSample or itsample.\n\nAdapted from algorithm R described in \"Random sampling with a reservoir, J. S. Vitter, 1985\".\n\n\n\n\n\n","category":"type"},{"location":"api/#StreamSampling.AlgL","page":"API","title":"StreamSampling.AlgL","text":"Implements random reservoir sampling without replacement. To be used with ReservoirSample or itsample.\n\nAdapted from algorithm L described in \"Random sampling with a reservoir, J. S. Vitter, 1985\".\n\n\n\n\n\n","category":"type"},{"location":"api/#StreamSampling.AlgRSWRSKIP","page":"API","title":"StreamSampling.AlgRSWRSKIP","text":"Implements random reservoir sampling with replacement. To be used with ReservoirSample or itsample.\n\nAdapted fron algorithm RSWR-SKIP described in \"Reservoir-based Random Sampling with Replacement from  Data Stream, B. Park et al., 2008\".\n\n\n\n\n\n","category":"type"},{"location":"api/#StreamSampling.AlgARes","page":"API","title":"StreamSampling.AlgARes","text":"Implements weighted random reservoir sampling without replacement. To be used with ReservoirSample or itsample.\n\nAdapted from algorithm A-Res described in \"Weighted random sampling with a reservoir, P. S. Efraimidis et al., 2006\".\n\n\n\n\n\n","category":"type"},{"location":"api/#StreamSampling.AlgAExpJ","page":"API","title":"StreamSampling.AlgAExpJ","text":"Implements weighted random reservoir sampling without replacement. To be used with ReservoirSample or itsample.\n\nAdapted from algorithm A-ExpJ described in \"Weighted random sampling with a reservoir, P. S. Efraimidis et al., 2006\".\n\n\n\n\n\n","category":"type"},{"location":"api/#StreamSampling.AlgWRSWRSKIP","page":"API","title":"StreamSampling.AlgWRSWRSKIP","text":"Implements weighted random reservoir sampling with replacement. To be used with ReservoirSample or itsample.\n\nAdapted from algorithm WRSWR-SKIP described in \"Weighted Reservoir Sampling with Replacement from Multiple Data Streams, A. Meligrana, 2024\". \n\n\n\n\n\n","category":"type"},{"location":"api/#StreamSampling.AlgD","page":"API","title":"StreamSampling.AlgD","text":"Implements random sampling without replacement. To be used with StreamSample or itsample.\n\nAdapted from algorithm D described in \"An Efficient Algorithm for Sequential Random Sampling, J. S. Vitter, 1987\".\n\n\n\n\n\n","category":"type"},{"location":"api/#StreamSampling.AlgORDSWR","page":"API","title":"StreamSampling.AlgORDSWR","text":"Implements random stream sampling with replacement. To be used with StreamSample or itsample.\n\nAdapted from algorithm 4 described in \"Generating Sorted Lists of Random Numbers, J. L. Bentley et al., 1980\".\n\n\n\n\n\n","category":"type"},{"location":"benchmark/#Benchmark-Comparison","page":"Benchmark Comparison","title":"Benchmark Comparison","text":"","category":"section"},{"location":"benchmark/","page":"Benchmark Comparison","title":"Benchmark Comparison","text":"Using these sampling techniques can bring down considerably the memory usage of the program,  but there are cases where they are also more time efficient, as demostrated below with a comparison with the  equivalent methods of StatsBase.sample:","category":"page"},{"location":"benchmark/","page":"Benchmark Comparison","title":"Benchmark Comparison","text":"(Image: image)","category":"page"},{"location":"benchmark/","page":"Benchmark Comparison","title":"Benchmark Comparison","text":"The “collection-based with setup” methods consider collecting the iterator in memory as part of the benchmark. The code to reproduce this benchmark is in benchmarkcomparisonstream.jl.","category":"page"},{"location":"#StreamSampling.jl","page":"StreamSampling.jl","title":"StreamSampling.jl","text":"","category":"section"},{"location":"","page":"StreamSampling.jl","title":"StreamSampling.jl","text":"StreamSampling","category":"page"},{"location":"#StreamSampling","page":"StreamSampling.jl","title":"StreamSampling","text":"StreamSampling.jl\n\n(Image: CI) (Image: ) (Image: codecov) (Image: Aqua QA) (Image: DOI)\n\nThe scope of this package is to provide general methods to sample from any stream in a single pass through the data, even when  the number of items contained in the stream is unknown.\n\nThis has some advantages over other sampling procedures:\n\nIf the iterable is lazy, the memory required is a small constant or grows in relation to the size of the sample, instead of the all population.\nWith reservoir methods, the sample collected is a random sample of the portion of the stream seen thus far at any point of the sampling process.\nIn some cases, sampling with the techniques implemented in this library can bring considerable performance gains, since the population of items doesn't need to be previously stored in memory.\n\nFor information about the available functionalities consult the documentation.\n\nContributing\n\nContributions are welcome! If you encounter any issues, have suggestions for improvements, or would like to add new  features, feel free to open an issue or submit a pull request.\n\n\n\n\n\n","category":"module"},{"location":"#Overview-of-the-functionalities","page":"StreamSampling.jl","title":"Overview of the functionalities","text":"","category":"section"},{"location":"","page":"StreamSampling.jl","title":"StreamSampling.jl","text":"The itsample function allows to consume all the stream at once and return the sample collected:","category":"page"},{"location":"","page":"StreamSampling.jl","title":"StreamSampling.jl","text":"julia> using StreamSampling\n\njulia> st = 1:100;\n\njulia> itsample(st, 5)\n5-element Vector{Int64}:\n  9\n 15\n 52\n 96\n 91","category":"page"},{"location":"","page":"StreamSampling.jl","title":"StreamSampling.jl","text":"In some cases, one needs to control the updates the ReservoirSample will be subject to. In this case you can simply use the fit! function to update the reservoir:","category":"page"},{"location":"","page":"StreamSampling.jl","title":"StreamSampling.jl","text":"julia> using StreamSampling\n\njulia> st = 1:100;\n\njulia> rs = ReservoirSample{Int}(5);\n\njulia> for x in st\n           fit!(rs, x)\n       end\n\njulia> value(rs)\n5-element Vector{Int64}:\n  7\n  9\n 20\n 49\n 74","category":"page"},{"location":"","page":"StreamSampling.jl","title":"StreamSampling.jl","text":"If the total number of elements in the stream is known beforehand and the sampling is unweighted, it is also possible to iterate over a StreamSample like so","category":"page"},{"location":"","page":"StreamSampling.jl","title":"StreamSampling.jl","text":"julia> using StreamSampling\n\njulia> st = 1:100;\n\njulia> ss = StreamSample{Int}(st, 5, 100);\n\njulia> r = Int[];\n\njulia> for x in ss\n           push!(r, x)\n       end\n\njulia> r\n5-element Vector{Int64}:\n 10\n 22\n 26\n 35\n 75","category":"page"},{"location":"","page":"StreamSampling.jl","title":"StreamSampling.jl","text":"The advantage of StreamSample iterators in respect to ReservoirSample is that they require O(1) memory if not collected, while reservoir techniques require O(k) memory where k is the number of elements in the sample.","category":"page"},{"location":"","page":"StreamSampling.jl","title":"StreamSampling.jl","text":"Consult the API page for more information about the package interface.","category":"page"},{"location":"example/#An-Illustrative-Example","page":"An Illustrative Example","title":"An Illustrative Example","text":"","category":"section"},{"location":"example/","page":"An Illustrative Example","title":"An Illustrative Example","text":"Suppose to receive data about some process in the form of a stream and you want to detect if anything is going wrong in the data being received. A reservoir  sampling approach could be useful to evaluate properties on the data stream.  This is a demonstration of such a use case using StreamSampling.jl. We will assume that the monitored statistic in this case is the mean of the data, and  you want that to be lower than a certain threshold otherwise some malfunctioning is expected.","category":"page"},{"location":"example/","page":"An Illustrative Example","title":"An Illustrative Example","text":"julia> using StreamSampling, Statistics, Random\n\njulia> function monitor(stream, thr)\n           rng = Xoshiro(42)\n           # we use a reservoir sample of 10^4 elements\n           rs = ReservoirSample{Int}(rng, 10^4)\n           # we loop over the stream and fit the data in the reservoir\n           for (i, e) in enumerate(stream)\n               fit!(rs, e)\n               # we check the mean value every 1000 iterations\n               if iszero(mod(i, 1000)) && mean(value(rs)) >= thr\n                   return rs\n               end\n           end\n       end","category":"page"},{"location":"example/","page":"An Illustrative Example","title":"An Illustrative Example","text":"We use some toy data for illustration","category":"page"},{"location":"example/","page":"An Illustrative Example","title":"An Illustrative Example","text":"julia> stream = 1:10^8; # the data stream\n\njulia> thr = 2*10^7; # the threshold for the mean monitoring","category":"page"},{"location":"example/","page":"An Illustrative Example","title":"An Illustrative Example","text":"Then, we run the monitoring","category":"page"},{"location":"example/","page":"An Illustrative Example","title":"An Illustrative Example","text":"julia> rs = monitor(stream, thr);","category":"page"},{"location":"example/","page":"An Illustrative Example","title":"An Illustrative Example","text":"The number of observations until the detection is triggered is given by","category":"page"},{"location":"example/","page":"An Illustrative Example","title":"An Illustrative Example","text":"julia> nobs(rs)\n40009000","category":"page"},{"location":"example/","page":"An Illustrative Example","title":"An Illustrative Example","text":"which is very close to the true value of 4*10^7 - 1 observations.","category":"page"},{"location":"example/","page":"An Illustrative Example","title":"An Illustrative Example","text":"Note that in this case we could use an online mean methods,  instead of holding all the sample into memory. However,  the approach with the sample is more general because it allows to estimate any statistic about the stream. ","category":"page"}]
}
