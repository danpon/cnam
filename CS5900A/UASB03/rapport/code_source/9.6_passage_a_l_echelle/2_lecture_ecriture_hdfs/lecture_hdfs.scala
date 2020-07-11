// lecture dans HDFS
val tweets1234DS = spark.read.textFile("hdfs://master.local:9000/twitter/tweets_1234.txt")
