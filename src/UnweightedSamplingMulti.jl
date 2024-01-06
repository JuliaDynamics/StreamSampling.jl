
function itsample(iter, n::Int; replace = false, ordered = false)
    return itsample(Random.default_rng(), iter, n; replace=replace, ordered=ordered)
end

function itsample(rng::AbstractRNG, iter, n::Int; 
        replace = false, ordered = false)
    IterHasKnownSize = Base.IteratorSize(iter)
    iter_type = Base.@default_eltype(iter)
    if IterHasKnownSize isa NonIndexable
        reservoir_sample(rng, iter, n, Val(replace), Val(ordered))::Vector{iter_type}
    else
        sortedindices_sample(rng, iter, n, replace, ordered)::Vector{iter_type}
    end
end

function reservoir_sample(rng, iter, n::Int, ::Val{false}, ::Val{false})
    iter_type = Base.@default_eltype(iter)
    it = iterate(iter)
    isnothing(it) && return iter_type[]
    el, state = it
    reservoir = Vector{iter_type}(undef, n)
    reservoir[1] = el
    for i in 2:n
        it = iterate(iter, state)
        isnothing(it) && return shuffle!(rng, reservoir[1:i-1])
        el, state = it
        @inbounds reservoir[i] = el
    end
    u = randexp(rng)
    while true
        w = exp(-u/n)
        skip_counter = ceil(Int, randexp(rng)/log(1-w))
        while skip_counter != 0
            skip_res = iterate(iter, state)
            isnothing(skip_res) && return shuffle!(rng, reservoir)
            state = skip_res[2]
            skip_counter += 1
        end
        it = iterate(iter, state)
        isnothing(it) && return shuffle!(rng, reservoir)
        el, state = it
        @inbounds reservoir[rand(rng, 1:n)] = el 
        u += randexp(rng)
    end
end

function reservoir_sample(rng, iter, n::Int, ::Val{false}, ::Val{true})
    iter_type = Base.@default_eltype(iter)
    it = iterate(iter)
    isnothing(it) && return iter_type[]
    el, state = it
    reservoir = Vector{iter_type}(undef, n)
    reservoir[1] = el
    for i in 2:n
        it = iterate(iter, state)
        isnothing(it) && return reservoir[1:i-1]
        el, state = it
        @inbounds reservoir[i] = el
    end
    u = randexp(rng)
    o = [i for i in 1:n]
    k = n
    while true
        w = exp(-u/n)
        skip_counter = ceil(Int, randexp(rng)/log(1-w))
        k += -skip_counter
        while skip_counter != 0
            skip_res = iterate(iter, state)
            isnothing(skip_res) && return reservoir[sortperm(o)]
            state = skip_res[2]
            skip_counter += 1
        end
        it = iterate(iter, state)
        k += 1
        isnothing(it) && return reservoir[sortperm(o)]
        el, state = it
        v = rand(rng, 1:n)
        @inbounds reservoir[v] = el
        @inbounds o[v] = k
        u += randexp(rng)
    end
end

function reservoir_sample(rng, iter, n::Int, ::Val{true}, ::Val{false})
    iter_type = Base.@default_eltype(iter)
    it = iterate(iter)
    isnothing(it) && return iter_type[]
    reservoir = Vector{iter_type}(undef, n)
    el, state = it
    reservoir[1] = el
    @inbounds for i in 2:n
        it = iterate(iter, state)
        isnothing(it) && return sample(rng, resize!(reservoir, i-1), n)
        el, state = it
        reservoir[i] = el
    end
    reservoir = sample(rng, reservoir, n)
    i = n
    while true
        t = skip(rng, i, n)
        skip_counter = t
        while skip_counter != 0
            skip_res = iterate(iter, state)
            isnothing(skip_res) && return shuffle!(rng, reservoir)
            state = skip_res[2]
            skip_counter -= 1
        end
        it = iterate(iter, state)
        isnothing(it) && return shuffle!(rng, reservoir)
        el, state = it
        i += t + 1
        p = 1/i
        z = (1-p)^(n-2)
        q = rand(rng, Uniform(z*(1-p)*(1-p),1))
        k = choose(n, p, q, z)
        if k == 1
            r = rand(rng, 1:n)
            @inbounds reservoir[r] = el
        else
            @inbounds for j in 1:k
                r = rand(rng, j:n)
                reservoir[r] = el
                reservoir[r], reservoir[j] = reservoir[j], reservoir[r]
            end
        end 
    end
end

function reservoir_sample(rng, iter, n::Int, ::Val{true}, ::Val{true})
    iter_type = Base.@default_eltype(iter)
    it = iterate(iter)
    isnothing(it) && return iter_type[]
    el, state = it
    reservoir = Vector{iter_type}(undef, n)
    o = [1 for i in 1:n]
    for i in eachindex(reservoir)
        reservoir[i] = el
    end
    i = 1
    while true
        t = skip(rng, i, n)
        skip_counter = t
        while skip_counter != 0
            skip_res = iterate(iter, state)
            isnothing(skip_res) && return reservoir[sortperm(o)]
            state = skip_res[2]
            skip_counter -= 1
        end
        it = iterate(iter, state)
        isnothing(it) && return reservoir[sortperm(o)]
        el, state = it
        i += t + 1
        p = 1/i
        z = (1-p)^(n-3)
        q = rand(rng, Uniform(z*(1-p)*(1-p)*(1-p),1))
        k = choose(n, p, q, z)
        if k == 1
            r = rand(rng, 1:n)
            @inbounds reservoir[r] = el
            @inbounds o[r] = i
        else
            @inbounds for j in 1:k
                r = rand(rng, j:n)
                reservoir[r] = el
                reservoir[r], reservoir[j] = reservoir[j], reservoir[r]
                o[r], o[j] = o[j], i
            end
        end 
    end
end

function skip(rng, n, m)
    q = rand(rng)^(1/m)
    t = ceil(Int, n/q - n - 1)
    return t
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
    b = Binomial(n, p)
    return quantile(b, q)
end

function double_scan_sampling(rng, iter, n::Int, replace, ordered)
    N = get_population_size(iter)
    sortedindices_sample(rng, iter, n, N, replace, ordered)
end

function sortedindices_sample(rng, iter, n::Int, replace, ordered)
    return sortedindices_sample(rng, iter, n, length(iter), replace, ordered)
end

function sortedindices_sample(rng, iter, n::Int, N::Int, replace, ordered)
    if N <= n
        reservoir = collect(iter)
        if replace
            return sample(rng, reservoir, n, ordered=ordered)
        else
            if ordered
                return reservoir
            else
                return shuffle!(rng, reservoir)
            end
        end
    end
    iter_type = Base.@default_eltype(iter)
    it = iterate(iter)
    el, state = it
    reservoir = Vector{iter_type}(undef, n)
    indices = get_sorted_indices(rng, n, N, replace)
    @inbounds skip_counter = indices[1] - 2
    if skip_counter < 0
        reservoir[1] = el
    else
        while skip_counter != 0
            skip_res = iterate(iter, state)
            state = skip_res[2]
            skip_counter -= 1
        end
        it = iterate(iter, state)
        el, state = it
        @inbounds reservoir[1] = el
    end
    i = 2
    while i <= n
        @inbounds skip_counter = indices[i] - indices[i-1] - 1
        if skip_counter < 0
            @inbounds reservoir[i] = el
        else
            while skip_counter != 0
                skip_res = iterate(iter, state)
                state = skip_res[2]
                skip_counter -= 1
            end
            it = iterate(iter, state)
            el, state = it
            @inbounds reservoir[i] = el
        end
        i += 1
    end
    if ordered
        return reservoir
    else
        return shuffle!(rng, reservoir)
    end
end

function get_population_size(iter)
    n = 0
    it = iterate(iter)
    while !isnothing(it)
        n += 1
        @inbounds state = it[2]
        it = iterate(iter, state)
    end
    return n
end

function get_sorted_indices(rng, n, N, replace)
    if replace == true
        return sortedrandrange(rng, 1:N, n)
    else
        return sort!(sample(rng, 1:N, n; replace=replace))
    end
end
