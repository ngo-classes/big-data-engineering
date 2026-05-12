import numpy as np

np.random.seed(0) # set static random seed to guarantee reproducibility

# Define the dimensions of the matrix and vector
N = 4

# Generate one random matrix and one random vector with the following dimensions:
# Matrix M (N x N)
# Vector V (N)
M = np.random.randint(0, 10, size=(N, N))
V = np.random.randint(0, 10, size=N)
P = np.matmul(M, V)

# Print the matrices
print(f"Matrix M:\n {M}")
print(f"Vector N:\n {V}")
print(f"Dot Product P:\n {P}")

# In this cell, we are pairing up individual elements of M and V
map_list = []

for i in range(N):
  for j in range(N):
    map_list.append((i,(M[i,j],V[j])))

print(f"Pairing up individual elements of M and V:")
for pair in map_list:
  print(pair)

# We can go ahead and multiply the paired up elements of M and V, and store the results in a list of tuples (i, M[i,j] * V[j])
map_list = []
for i in range(N):
  for j in range(N):
    map_list.append((i,M[i,j] * V[j]))

print("Multiplying the paired up elements of M and V:")
for pair in map_list:
  print(pair)

list_Q = []
for i in range(N):
  list_tmp = [value for key, value in map_list if key == i]
  list_Q.append(sum(list_tmp))

print(f"MapReduce Matrix Q:\n {np.array(list_Q)}")
print(f"Matrix P:\n {P}")