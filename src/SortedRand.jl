
function sortedrandrange(rng, range, n)
	exp_rands = randexp(rng, n)
	sorted_rands = accumulate!(+, exp_rands, exp_rands)
	a, b = range.start, range.stop
	range_size = b-a+1
	cum_step = (sorted_rands[end] + randexp(rng)) / range_size
	sorted_rands ./= cum_step
	return ceil.(Int, sorted_rands)
end
