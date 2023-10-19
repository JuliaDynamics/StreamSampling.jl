function sortedrand(rng, n)
	exp_rands = randexp(rng, n)
	sorted_rands = accumulate!(+, exp_rands, exp_rands)
	sorted_rands ./= sorted_rands[end] + randexp(rng)
	return sorted_rands
end

function sortedrandrange(rng, range, n)
	exp_rands = randexp(rng, n)
	sorted_rands = accumulate!(+, exp_rands, exp_rands)
	a, b = range.start, range.stop
	range_size = b-a+1
	cum_step = (sorted_rands[end] + randexp(rng)) / range_size
	if range_size <= n/20
		sorted_range_rands = informed_binary_search(sorted_rands, cum_step, range_size)
	else
		sorted_range_rands = each_divide_and_ceil(sorted_rands, cum_step)
	end
	if sorted_range_rands[1] >= a && sorted_range_rands[end] <= b 
		return sorted_range_rands
	else
		return check_inrange(sorted_range_rands, a, b)
	end
end

function each_divide_and_ceil(sorted_rands, cum_step)
	sorted_rands ./= cum_step
	return ceil.(Int, sorted_rands)
end

function informed_binary_search(sorted_rands, cum_step, range_size)
	@inbounds begin
		n = length(sorted_rands)
		p = 1/range_size
		conf_int = 2.576*sqrt(p*(1-p)*n)
		l_int = clamp(round(Int, n*p - conf_int), 1, n)
		r_int = clamp(round(Int, n*p + conf_int), 1, n)
		start_idx = 1
		sorted_range_rands = Vector{Int}(undef, n)
		j = 1
		while start_idx < n
			l_conf, r_conf = min(start_idx+l_int, n), min(start_idx+r_int, n)
			lo, hi = sorted_rands[l_conf], sorted_rands[r_conf]
			new_endpoint = cum_step*j
			if lo <= new_endpoint <= hi
				idx_s = l_conf
				range_in = @view(sorted_rands[l_conf+1:r_conf])
			elseif new_endpoint < lo
				idx_s = start_idx
				range_in = @view(sorted_rands[start_idx+1:l_conf])
			else
				idx_s = r_conf
				range_in = @view(sorted_rands[r_conf+1:end])
			end
			idx_in = searchsortedlast(range_in, new_endpoint)
			k = ceil(Int, sorted_rands[start_idx] / cum_step)
			last_idx = idx_s+idx_in
			for i in start_idx:last_idx
				sorted_range_rands[i] = k
			end
			j += 1
			start_idx = last_idx + 1
		end
	end
	return sorted_range_rands
end

function check_inrange(sorted_range_rands, a, b)
	i = 1
	while sorted_range_rands[i] < a
		sorted_range_rands[i] = a
		i += 1
	end
	i = length(sorted_range_rands)
	while sorted_range_rands[i] > b
		sorted_range_rands[i] = b
		i -= 1
	end
	return sorted_range_rands
end
