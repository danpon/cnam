import org.apache.spark.ml.feature.Word2Vec
import org.apache.spark.ml.feature.Word2VecModel
import com.cloudera.datascience.lsa._
import com.cloudera.datascience.lsa.ParseWikipedia._
import org.apache.spark.ml.stat.Summarizer
import org.apache.spark.sql.SQLContext
import org.apache.spark.ml.tuning.CrossValidatorModel
import org.apache.spark._
import org.apache.spark.streaming._
import org.apache.spark.streaming.StreamingContext._

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Code Spark  qui:
// 1) scrute (avec Spark Streaming) le répertoire "notifications" dans lequel apparaissent les fichiers contenant
//   les identifiants d'utilisateurs à traiter
// 2) lit, dans le répertoire "tweets", le fichier contenant le texte des messages de l'utilisateur à traiter
// 3) à partir des messages postés par l'utilisateur applique la classification "deprime/non deprime"
// 4) écrit le résultat dans un fichier csv
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Effectue la classification sur un utilisateur dont l'identifiant (user_id) est passé en paramètre.
// La classification est basée sur le texte des 50 derniers tweets de l'utilisateur.
// Les tweets sont stockés dans le fichier "tweets/[user_id].txt".
// Le résultat de la classification est stocké dans dans le fichier "resultats/[user_id].csv".
def processUserTweets(user_id:String,stopWords:Set[String],w2vModel: Word2VecModel, cvLogRegModel: CrossValidatorModel) = {
  val path = "tweets/".concat(user_id).concat(".txt")

  val tweetsRDD = spark.sparkContext.textFile(path).
		flatMap(text => text.split("\n").map(tweet => (user_id,tweet ) ) ).
		mapPartitions(iter => {
               		val pipeline = ParseWikipedia.createNLPPipeline();
               		iter.map{ case(user,tweet) =>
                             (user,ParseWikipedia.plainTextToLemmas(tweet, stopWords, pipeline))};
           	}).
		filter(t => t._2.size >= 1).
		cache()

	val tweetsDF = spark.createDataFrame(tweetsRDD).toDF("user","text")


	val tweetsFeaturesDF = w2vModel.transform(tweetsDF).
				 	groupBy($"user").
					agg(Summarizer.mean($"features").alias("features"))


  val resultats = cvLogRegModel.transform(tweetsFeaturesDF)
                               .select("user", "prediction")
 	resultats.show()

  resultats.coalesce(1).write.format("csv").option("header", "true")
                  .csv("resultats/".concat(user_id).concat(".csv"))
}


val w2vModel = Word2VecModel.load("data/output/w2vModel")
val stopWords = sc.broadcast(ParseWikipedia.loadStopWords("deps/lsa/src/main/resources/stopwords.txt")).value
// lecture du modèle de classification (regression logistique)
val cvLogRegModel =  CrossValidatorModel.load("data/output/cv_logreg_model")

// création du flux avec une fenêtre de 10 secondes
val ssc = new StreamingContext(sc, Seconds(10))

// scrute dans le répertoire "notifications"  l'apparition de fichiers
// chaque fichier de notification contient l'identifiant d'un utilisateur Twitter à traiter
val lines = ssc.textFileStream("notifications")
lines.foreachRDD(rdd => {
  if ((rdd != null) && (rdd.count() > 0) && (!rdd.isEmpty()) ) {
    // déclenche une classification pour chaque identifiant utilisateur lu dans les fichiers de notification
    rdd.collect().foreach(user_id => processUserTweets(user_id,stopWords,w2vModel,cvLogRegModel))
  }
})

// démarrage du traitement du flux
ssc.start()
ssc.awaitTermination()
