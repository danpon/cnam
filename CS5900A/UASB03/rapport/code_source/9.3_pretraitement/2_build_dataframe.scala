import org.apache.spark.ml.feature.Word2Vec
import org.apache.spark.ml.feature.Word2VecModel
import com.cloudera.datascience.lsa._
import com.cloudera.datascience.lsa.ParseWikipedia._
import org.apache.spark.ml.stat.Summarizer
import org.apache.spark.sql.Dataset
import org.apache.spark.sql.Row

sc.setLogLevel("ERROR")

def buildDataframe(inputDirectory: String,  stopWords:Set[String],w2vModel: Word2VecModel,label:Double) : Dataset[Row] = {

  // lecture des tweets, suppression de stop words et lemmatisation
	val tweetsRDD = spark.sparkContext.wholeTextFiles(inputDirectory).
		flatMap(l => l._2.split("\n").map(tweet => (label,l._1.split("/").last,tweet ) ) ).
		mapPartitions(iter => {
               		val pipeline = ParseWikipedia.createNLPPipeline();
               		iter.map{ case(label,user,tweet) =>
                             (label,user,ParseWikipedia.plainTextToLemmas(tweet, stopWords, pipeline))};
           	}).
		filter(t => t._3.size >= 1).
		cache()

	val tweetsDF = spark.createDataFrame(tweetsRDD).toDF("label","user","text")

	// application du modèle word2vec au texte :
	// ceci se traduit par la création d'un nouveau dataframe
	// comportant une colonne "features"
	// représentant le texte sous forme vectorielle
	val tweetsFeaturesDF = w2vModel.transform(tweetsDF).
				 	groupBy($"label",$"user").
					agg(Summarizer.mean($"features").alias("features"))

	return tweetsFeaturesDF
}

val stopWords = sc.broadcast(ParseWikipedia.loadStopWords("deps/lsa/src/main/resources/stopwords.txt")).value
val w2vModel = Word2VecModel.load("data/output/w2vModel")

val trainDepressedDF=buildDataframe("data/input/train/depressed",stopWords,w2vModel,1.0)
val trainUndepressedDF=buildDataframe("data/input/train/undepressed",stopWords,w2vModel,0.0)
val trainDF = trainDepressedDF.union(trainUndepressedDF)
trainDF.write.parquet("data/output/trainDF")


val testDepressedDF=buildDataframe("data/input/test/depressed",stopWords,w2vModel,1.0)
val testUndepressedDF=buildDataframe("data/input/test/undepressed",stopWords,w2vModel,0.0)
val testDF = testDepressedDF.union(testUndepressedDF)
testDF.write.parquet("data/output/testDF")
