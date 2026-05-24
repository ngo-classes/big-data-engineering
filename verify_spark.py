import os
import sys
import pathlib
import platform
import importlib.util


#### Verify Spark can start and run a simple operation

from pyspark.sql import SparkSession

try:
    builder = (
        SparkSession.builder
        .appName("VersionCheck")
        .master("local[*]")
    )

    spark = builder.getOrCreate()
    spark.sparkContext.setLogLevel("ERROR")
    print(f"Spark Version: {spark.version}")

    # Test a simple operation
    df = spark.createDataFrame([{"test": "Success"}])
    df.show()
    spark.stop()
except Exception as e:
    print(f"Spark failed to start: {e}")