import sys
from pyspark.sql import SparkSession

# This function calculates the contribution of a node's PageRank to its neighbors based on the number of outgoing links.
# t format is (node, (rank, [neighbor1, neighbor2, ...]))
def calculateVotes(t):
    res = [] # list to store the contributions to neighbors
    for item in t[1][1]: # iterate over the neighbors of the node
        count = len(t[1][1]) # count the number of outgoing links (neighbors)
        res.append((item, t[1][0] / count)) # calculate the contribution to each neighbor and append to the result list
    return res

def pagerank(input_path: str, output_path: str):
    try:
        spark = SparkSession.builder.appName("PageRank").getOrCreate()
        sc = spark.sparkContext

        # Load and view (a portion of) the data
        graph_data = sc.textFile(input_path)
        print(f"Graph data sample: {graph_data.take(5)}")
        
        # Create links ######################################################

        # Each line in the input file is expected to be in the format: "source destination"
        # This creates an RDD of (source, destination) pairs
        links = graph_data.map(lambda line: (line.split(" ")[0], line.split(" ")[1]))

        # View the first 10 links to verify the transformation
        print(links.take(10))

        # Group the links by source node to create an RDD of (source, [destination1, destination2, ...]) pairs
        links = links.groupByKey()

        # View the first 10 grouped links to verify the transformation
        print(links.take(10))

        # Convert the grouped links to a list format for easier processing in the PageRank algorithm
        links = links.mapValues(list)
        print(links.take(10))

        # Setup initial weight ######################################################

        # Count the total number of unique nodes in the graph to initialize the PageRank values
        N = links.count()

        # Initialize the PageRank values for each node to 1/N
        ranks = links.map(lambda line: (line[0], 1/N))

        # View the initial ranks to verify the transformation
        print(ranks.take(3))

        # Calculate the votes ######################################################

        # Join the ranks with the links to calculate the votes each node receives from its neighbors
        votes = ranks.join(links)
        print(votes.take(10))

        # Calculate the contribution of each node to its neighbors' PageRank values
        votes = votes.flatMap(calculateVotes)
        print(votes.take(10))

        # Tally votes ######################################################

        # Sum the contributions to calculate the new PageRank values for each node
        ranks = votes.reduceByKey(lambda x,y: x + y)
        print(ranks.take(10))

        # Iteration in Spark with a stopping condition
        for i in range(10):
          votes = ranks.join(links).flatMap(calculateVotes) # calculate the contributions based on the current ranks
          ranks = votes.reduceByKey(lambda x,y: x + y) # sum the contributions to get the new ranks
          print(f"Iteration {i}: {ranks.take(3)}") # print the ranks after each iteration to monitor convergence

        # Save the final PageRank values to the output path
        ranks.saveAsTextFile(output_path)
        spark.stop()
    except Exception as e:
        print(f"Spark failed to start: {e}")

if __name__ == "__main__":
    pagerank(sys.argv[1], sys.argv[2])
