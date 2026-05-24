import sys
import os
import subprocess
from pyspark.sql import SparkSession

def check_setup():
    # 1. Check Python Version
    print(f"Python Version: {sys.version.split()[0]}")

    # 2. Check Java Version
    try:
        java_version = subprocess.check_output(['java', '-version'], stderr=subprocess.STDOUT).decode()
        print(f"Java Version Info:\n{java_version.strip()}")
    except Exception as e:
        print("Java not found in PATH.")

    # 3. Initialize Spark and Check Version
    try:
        spark = SparkSession.builder.appName("VersionCheck").master("local[*]").getOrCreate()
        print(f"Spark Version: {spark.version}")
        
        # Test a simple operation
        df = spark.createDataFrame([{"test": "Success"}])
        df.show()
        
        spark.stop()
    except Exception as e:
        print(f"Spark failed to start: {e}")

if __name__ == "__main__":
    check_setup()
