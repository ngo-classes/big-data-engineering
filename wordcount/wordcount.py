import sys
import os
import subprocess
from pyspark.sql import SparkSession

def wordcount(input_path: str, output_path: str):
    try:
        spark = SparkSession.builder.appName("WordCount").getOrCreate()
        sc = spark.sparkContext
        wordcount = sc.textFile(input_path) \
            .flatMap(lambda line: line.split(" ")) \
            .filter(lambda word: word != "") \
            .map(lambda word: (word, 1)) \
            .reduceByKey(lambda a, b: a + b) 
        wordcount.saveAsTextFile(output_path)
        spark.stop()
    except Exception as e:
        print(f"Spark failed to start: {e}")

if __name__ == "__main__":
    wordcount(sys.argv[1], sys.argv[2])
