import sys
import numpy as np
from pyspark.sql import SparkSession

np.random.seed(123)

def matvec(N: int):
  try:
    spark = SparkSession.builder.appName("Vector and Matrix Multiplication").getOrCreate()
    sc = spark.sparkContext
    M = np.random.randint(5, size = (N, N))
    V = np.random.randint(5, size = N)
        
    P = np.matmul(M, V)

    # Print the matrices
    print(f"Matrix M:\n {M}")
    print(f"Vector N:\n {V}")
    print(f"Dot Product P:\n {P}")
    
    mspark = sc.parallelize(M)
    print(f"Parallelize M inside Spark Context:\n {mspark.take(4)}")

    mspark = sc.parallelize(M).zipWithIndex()
    print(f"Parallelize M inside Spark Context with Index:\n {mspark.take(4)}")

    mspark = (sc
              .parallelize(M)
              .zipWithIndex()
              .map(lambda item: item[0].dot(V))
    )

    print(f"MapReduce Dot Product:\n {np.array(mspark.take(4))}")
    print(f"Serial Dot Product P for comparison purposes:\n {P}")

    spark.stop()

  except Exception as e:
    print(f"Spark failed to start: {e}")

if __name__ == "__main__":
    matvec(int(sys.argv[1]))
