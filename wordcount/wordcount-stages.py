import sys
from pyspark.sql import SparkSession

def wordcount(input_path: str, output_path: str):
    try:
        spark = SparkSession.builder.appName("WordCount").getOrCreate()
        sc = spark.sparkContext
        wordcount = sc.textFile(input_path)

        wordcount_flatMap = wordcount.flatMap(lambda line: line.split(" "))
        wordcount_flatMap.saveAsTextFile(output_path + "_flatMap")

        wordcount_filter = wordcount_flatMap.filter(lambda word: word != "")
        wordcount_filter.saveAsTextFile(output_path + "_filter")

        wordcount_map = wordcount_filter.map(lambda word: (word, 1))
        wordcount_map.saveAsTextFile(output_path + "_map")

        wordcount_reduceByKey = wordcount_map.reduceByKey(lambda a, b: a + b)
        wordcount_reduceByKey.saveAsTextFile(output_path + "_reduceByKey")
        
        spark.stop()
    except Exception as e:
        print(f"Spark failed to start: {e}")

if __name__ == "__main__":
    wordcount(sys.argv[1], sys.argv[2])
