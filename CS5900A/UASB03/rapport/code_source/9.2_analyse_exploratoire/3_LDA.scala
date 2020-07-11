import com.cloudera.datascience.lsa._
import com.cloudera.datascience.lsa.ParseWikipedia._
import org.apache.spark.sql.Dataset
import org.apache.spark.sql.Row
import org.apache.spark.ml.feature.{HashingTF, IDF, Tokenizer}
import org.apache.spark.ml.clustering.LDA
import org.apache.spark.ml.feature.{CountVectorizer, CountVectorizerModel}
import scala.collection.mutable.WrappedArray

sc.setLogLevel("ERROR")


def buildLDATopics(inputDirectory: String,  stopWords:Set[String],outputFile:String) = {
	
	val tweetsRDD = spark.sparkContext.wholeTextFiles(inputDirectory).
		flatMap(l => l._2.split("\n").map(tweet => (l._1.split("/").last,tweet ) ) ).
		mapPartitions(iter => {
               		val pipeline = ParseWikipedia.createNLPPipeline();
               		iter.map{ case(user,tweet) =>
                             (user,ParseWikipedia.plainTextToLemmas(tweet, stopWords, pipeline))};
           	}).
		filter(t => t._2.size >= 1).
		cache()

	// dataframe construit à partir de tweetsRDD
	val tweets = spark.createDataFrame(tweetsRDD).toDF("user","text")

	// création d'une matrice de type TF IDF

	// 1) calcul TF avec CountVectorizer
	val cvModel: CountVectorizerModel = new CountVectorizer()
 				 .setInputCol("text")
  				 .setOutputCol("rawFeatures")
  				 .setVocabSize(2000)
  				 .setMinDF(2)
				 .fit(tweets)

	
	
	// extraction du vocabulaire (tableau de String) à partir du CountVectorizeModel
	val vocab = cvModel.vocabulary

	val tweetsTF= cvModel.transform(tweets)
	
	// 2) calcul IDF 
	val idfModel = new IDF()
			.setInputCol("rawFeatures")
			.setOutputCol("features")
			.fit(tweetsTF)
		
	
	val tweetsTFIDF = idfModel.transform(tweetsTF)

	tweetsTFIDF.show()
	
	// création du modèle LDA avec 10 topics
	val nbTopics=10

	val lda = new LDA().setK(nbTopics).setMaxIter(10)
	val model = lda.fit(tweetsTFIDF)

	// les mots définissant les topics sont représentés par un tableau d'entier correspondant 
	// à leurs indices dans le vocabulaire
        // la fonction toWords reconstitue la liste de mots à partir des indices et la place dans une String
	val toWords = udf( (x : WrappedArray[Int]) => { x.map(i => vocab(i)).mkString(", ") })
	val topics = model.describeTopics(nbTopics)
        	.withColumn("topicWords", toWords(col("termIndices")))
	
	
	val topicsWords = topics.select("topicWords")
	topicsWords.show()
	topicsWords.coalesce(1).write.format("csv").option("header", "true").csv(outputFile)
}

val stopWords = sc.broadcast(ParseWikipedia.loadStopWords("deps/lsa/src/main/resources/stopwords.txt")).value

buildLDATopics("data/input/train/depressed",stopWords,"data/output/topicsDepressed.csv")
buildLDATopics("data/input/train/undepressed",stopWords,"data/output/topicsUndepressed.csv")

