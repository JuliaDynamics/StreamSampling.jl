
function sorted_rand(rng, n)
	exp_rands = randexp(rng, n)
	sorted_rands = accumulate!(+, exp_rands, exp_rands)
	sorted_rands ./= sorted_rands[end] + randexp(rng)
	return sorted_rands
end

function sorted_rangerand(rng, range, n)
	exp_rands = randexp(rng, n)
	sorted_rands = accumulate!(+, exp_rands, exp_rands)
	a, b = range.start, range.stop
	range_size = b-a+1
	cum_step = (sorted_rands[end] + randexp(rng)) / range_size
	sorted_rands ./= cum_step
	sorted_range_rands = ceil.(Int, sorted_rands)
	if sorted_range_rands[1] >= a && sorted_range_rands[end] <= b 
		return sorted_range_rands
	else
		return check_inrange(sorted_range_rands, a, b)
	end
end

function check_inrange(sorted_range_rands, a, b)
	i = 1
	@inbounds while sorted_rands[i] < a
		sorted_rands[i] = a
		i += 1
	end
	i = length(sorted_range_rands)
	@inbounds while sorted_rands[i] > b
		sorted_rands[i] = b
		i -= 1
	end
	return sorted_range_rands
end
