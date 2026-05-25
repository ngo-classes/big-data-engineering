import sys
import numpy as np
from pyspark.sql import SparkSession

np.random.seed(123)

def getPos(t):
  res = []
  for idx,x in np.ndenumerate(t[1]):
    res.append((idx[0], (t[0], x.item()))) # (row, (column, cell value))
  return res

def arrayMul(t):
  res = []
  vectorVal = None
  for x in t[1]:
    if type(x) != tuple:
      vectorVal = x
  for x in t[1]:
    if isinstance(x, tuple):
      row_index = x[0]
      matrix_value = x[1]
      res.append((row_index, matrix_value * vectorVal))
  return res

def matvec(N: int):
  try:
    spark = SparkSession.builder.appName("Vector and Matrix Multiplication").getOrCreate()
    sc = spark.sparkContext
    M = np.random.randint(5, size = (N, N))
    V = np.random.randint(5, size = N)
        
    P = np.matmul(M, V)

    # Print the matrices
    print(f"Matrix M:\n {M}")
    print(f"Vector V:\n {V}")
    print(f"Dot Product P:\n {P}")
    
    mspark = sc.parallelize(M).zipWithIndex().map(lambda item: (item[1],item[0].tolist()))
    print(f"Parallelize M inside Spark Context with Index:")
    local_mspark = mspark.collect()
    for item in local_mspark:
      print(item)

    vspark = sc.parallelize(V).zipWithIndex().map(lambda item: (item[1],item[0].tolist()))
    print(f"Parallelize V inside Spark Context with Index:")
    local_vspark = vspark.collect()
    for item in local_vspark:
      print(item)

    pspark = (mspark
              .flatMap(getPos)
              .union(vspark)
              .groupByKey()
              .mapValues(list)
              .flatMap(arrayMul)
              .reduceByKey(lambda a, b: a + b)
    )
    
    print(f"MapReduce Dot Product:")
    local_pspark = pspark.collect()
    for item in local_pspark:
      print(item)

    #flatMap(arrayMul)

    #print(f"MapReduce Dot Product:\n {np.array(pspark.take(16))}")
    print(f"Serial Dot Product P for comparison purposes:\n {P}")

    spark.stop()

  except Exception as e:
    print(f"Spark failed to start: {e}")

if __name__ == "__main__":
    matvec(int(sys.argv[1]))
