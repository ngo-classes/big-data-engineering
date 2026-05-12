import numpy as np
np.random.seed(0) # set static random seed to guarantee reproducibility

# Define the dimensions of the matrices
I, J, K = 3, 4, 5

# Generate two random matrices with integer values between 0 and 9
# Matrix M (I x J)
# Matrix N (J x K)
M = np.random.randint(0, 10, size=(I, J))
N = np.random.randint(0, 10, size=(J, K))
P = np.matmul(M, N)

# Print the matrices
print(f"Matrix M:\n {M}")
print(f"Matrix N:\n {N}")
print(f"Matrix P:\n {P}")

print("First Pass ==================")
print("Map 1:")
map1_list = []
for i in range(I):
  for j in range(J):
    map1_list.append((j,('M',i, M[i,j])))

for j in range(J):
  for k in range(K):
    map1_list.append((j,('N',k, N[j,k])))

print(len(map1_list))
for pair in map1_list:
  print(pair)

print("Reduce 1:")
key_0 = [value for key, value in map1_list if key == 0]
for pair in key_0:
  print(pair)

key_M = [(value1, value2) for key, value1, value2 in key_0 if key == 'M']
key_N = [(value1, value2) for key, value1, value2 in key_0 if key == 'N']

reduce1_list = []

for m_pair in key_M:
  i, M_ij = m_pair
  for n_pair in key_N:
    k, N_kj = n_pair
    reduce1_list.append(((i,k), M_ij * N_kj))

for pair in reduce1_list:
  print(pair)

reduce1_list = []

for j in range(J):
  key_j = [value for key, value in map1_list if key == j]
  key_M = [(value1, value2) for key, value1, value2 in key_j if key == 'M']
  key_N = [(value1, value2) for key, value1, value2 in key_j if key == 'N']

  for m_pair in key_M:
    i, M_ij = m_pair
    for n_pair in key_N:
      k, N_kj = n_pair
      reduce1_list.append(((i,k), M_ij * N_kj))

print(len(reduce1_list))
for pair in reduce1_list:
  print(pair)

print("Second Pass ==================")
print("Map 2: We are not doing anything here, we are just passing the output of Reduce 1 to Reduce 2")
print("Reduce 2:")

key_0 = [value for key, value in reduce1_list if key == (0,0)]
for pair in key_0:
  print(pair)

""" - The sum of the above four elements: *40 + 0 + 24 + 9 = 73*, which is the value of cell *(0,0)* of resulting matrix P.
 - We can generalize the entire process as follows
"""

mapreduce_Q = []

for i in range(I):
  for k in range(K):
    key_Q = [value for key, value in reduce1_list if key == (i,k)]
    mapreduce_Q.append(sum(key_Q))


print(f"MapReduce Matrix Q:\n {np.array(mapreduce_Q).reshape(I,K)}")
print(f"Matrix P:\n {P}")

