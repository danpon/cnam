import com.cloudera.datascience.lsa._
import com.cloudera.datascience.lsa.ParseWikipedia._
import org.apache.spark.sql.Dataset
import org.apache.spark.sql.Row
import org.apache.spark.ml.Pipeline
import com.johnsnowlabs.nlp.pretrained.PretrainedPipeline
import com.johnsnowlabs.nlp.Finisher
import scala.collection.mutable.WrappedArray

sc.setLogLevel("ERROR")


def evaluateSentiment(inputDirectory: String, stopWords:Set[String], outputFile:String) = {

	val tweetsRDD = spark.sparkContext.wholeTextFiles(inputDirectory).
		flatMap(l => l._2.split("\n").map(tweet => (l._1.split("/").last,tweet ) ) ).
		mapPartitions(iter => {
               		val pipeline = ParseWikipedia.createNLPPipeline();
               		iter.map{ case(user,tweet) =>
                             (user,ParseWikipedia.plainTextToLemmas(tweet, stopWords, pipeline).mkString(" "))};
           	}).
		filter(t => t._2.size >= 1).
		cache()

	// dataframe construit à partir de tweetsRDD
	val tweetsDF = spark.createDataFrame(tweetsRDD).toDF("user","text")
	tweetsDF.show()

	// L'analyse de sentiment produite par SParkNLP (colonne "finished_sentiment")
	// est un tableau (avec un élément par phrase du texte analysé)
	// Cela pose problème pour l'export des résultats au format CSV.
	// On convertit donc le tableau en String avec la fonction ci-dessous
	// NB : dans notre cas les signes de ponctuation sont supprimés lors de la lemmatisation
	// chaque tweet est donc traité par SparkNLP comme une phrase unique et le tableau
	// ne comporte qu’un seul élément
	val fromArrayToString = udf( (x : WrappedArray[String]) => { x.mkString(", ") })


	val sentimentPipelineModel = PretrainedPipeline("analyze_sentiment").model
	val finisherSentiment = new Finisher().setInputCols("document","sentiment")
	val pipelineSentiment = new Pipeline().setStages(Array(sentimentPipelineModel,finisherSentiment))
	val modelSentiment = pipelineSentiment.fit(tweetsDF)
	val sentimentTweetsDF = modelSentiment.
				transform(tweetsDF).
				select("text","finished_sentiment").
				withColumn("sentiment", fromArrayToString(col("finished_sentiment"))).
				select("text","sentiment")

	sentimentTweetsDF.show()
	val sentimentCountDF = sentimentTweetsDF.groupBy("sentiment").count().sort($"count".desc)

	sentimentCountDF.show()

	sentimentTweetsDF.coalesce(1).write.format("csv").option("header", "true").csv(outputFile)
}

val stopWords = sc.broadcast(ParseWikipedia.loadStopWords("deps/lsa/src/main/resources/stopwords.txt")).value

// On ne garde pour chaque utilisateur que les 50 derniers tweets (répertoirtoire "input_truncated"):
// cela diminue le temps de traitement et évite que les sentiments des utilisateurs aynt posté
// de nombreux messages soient surreprésntés
evaluateSentiment("data/input_truncated/train/depressed",stopWords,"data/output/sentimentAnalysisDepressed.csv")
evaluateSentiment("data/input_truncated/train/undepressed",stopWords,"data/output/sentimentAnalysisUndepressed.csv")
