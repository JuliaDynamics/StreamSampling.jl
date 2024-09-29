
import numpy as np
import timeit

a = np.arange(1, 10**8+1, dtype=np.int64);
wsa = np.arange(1, 10**8+1, dtype=np.float64)
p = wsa/np.sum(wsa);

times_numpy = []
for i in range(8):
    ts = []
    for j in range(3):
    	t = timeit.timeit("np.random.choice(a, size=10**i, replace=True, p=p)", setup=f"from __main__ import a, p; import numpy as np; i={i}", number=1)
    	ts.append(t)
    times_numpy.append(ts[1])
    print(ts[1])