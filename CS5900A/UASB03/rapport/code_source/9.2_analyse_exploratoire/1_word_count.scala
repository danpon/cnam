
import com.cloudera.datascience.lsa._
import com.cloudera.datascience.lsa.ParseWikipedia._
import org.apache.spark.sql.Dataset
import org.apache.spark.sql.Row


sc.setLogLevel("ERROR")

def wordCount(inputDirectory: String,  stopWords:Set[String],outputFile : String) = {
  // lecture, lemmatisation et supppresion des stopWords
	val tweetsRDD = spark.sparkContext.wholeTextFiles(inputDirectory).
		flatMap(l => l._2.split("\n").map(tweet => (l._1.split("/").last,tweet ) ) ).
		mapPartitions(iter => {
               		val pipeline = ParseWikipedia.createNLPPipeline();
               		iter.map{ case(user,tweet) =>
                             (user,ParseWikipedia.plainTextToLemmas(tweet, stopWords, pipeline).mkString(" "))};
           	}).
		filter(t => t._2.size >= 1).
		cache()

	val tweetsDF = spark.createDataFrame(tweetsRDD).toDF("user","text")
	val wordsDF = tweetsDF.explode("text","word")((text: String) => text.split(" "))
  val wordCountDF = wordsDF.groupBy("word").count().sort($"count".desc)
  wordCountDF.show(50)
	wordCountDF.coalesce(1).write.format("csv").option("header", "true").csv(outputFile)
}

val stopWords = sc.broadcast(ParseWikipedia.loadStopWords("deps/lsa/src/main/resources/stopwords.txt")).value

wordCount("data/input/train/depressed",stopWords,"data/output/word_count_depressed")
wordCount("data/input/train/undepressed",stopWords,"data/output/word_count_undepressed")
