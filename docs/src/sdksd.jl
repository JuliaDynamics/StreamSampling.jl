
function weighted_reservoir_sample(rng, a, ws, n)
    m = min(length(a), n)
    view_w_f_n = ws[1:m]
    w_sum = sum(view_w_f_n)
    reservoir = sample(rng, a[1:m], Weights(view_w_f_n, w_sum), n)
    length(a) <= n && return reservoir
    w_skip = skip(rng, w_sum, n)
    @inbounds for i in n+1:length(a)
        w_el = ws[i]
        w_sum += w_el
        if w_sum > w_skip
            p = w_el/w_sum
            z = (1-p)^(n-3)
            q = rand(rng, Uniform(z*(1-p)*(1-p)*(1-p),1.0))
            k = choose(n, p, q, z)
            for j in 1:k
                r = rand(rng, j:n)
                reservoir[r] = a[i]
                reservoir[r], reservoir[j] = reservoir[j], reservoir[r]
            end 
            w_skip = skip(rng, w_sum, n)
        end
    end
    return shuffle!(rng, reservoir)
end

function skip(rng, w_sum::AbstractFloat, m)
    q = rand(rng)^(1/m)
    return w_sum/q
end

function choose(n, p, q, z)
    m = 1-p
    s = z
    z = s*m*m*(m + n*p)
    z > q && return 1
    z += n*p*(n-1)*p*s*m/2
    z > q && return 2
    z += n*p*(n-1)*p*(n-2)*p*s/6
    z > q && return 3
    return quantile(Binomial(n, p), q)
end

using BenchmarkTools, Random, StatsBase, Distributions

rng = Xoshiro(42);
a = collect(1:10^7);
wv(el) = rand() < 0.1 ? 10 * rand() : rand()
ws = Weights(wv.(a))

weighted_reservoir_sample(rng, a, ws, 1)
weighted_reservoir_sample(rng, a, ws, 10^4)
sample(rng, a, ws, 1)
sample(rng, a, ws, 10^4)

for i in 0:7
    t1 = @elapsed weighted_reservoir_sample(rng, a, ws, 10^i);
    t2 = @elapsed sample(rng, a, ws, 10^i);
    println(t2/t1)
end