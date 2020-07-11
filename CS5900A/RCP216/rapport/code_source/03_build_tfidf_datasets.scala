import com.cloudera.datascience.lsa._
import com.cloudera.datascience.lsa.ParseWikipedia._
import org.apache.spark.sql.{Dataset,Row}
import org.apache.spark.ml.feature.{HashingTF, IDF, Tokenizer}

// pathDataPos : emplacement des avis positifs
// pathDataNeg : emplacement des avis négatifs
// stopWords   : collection de stop words
def buildDataframe(pathDataPos: String, pathDataNeg : String, stopWords:Set[String]) : Dataset[Row] = {

    // lecture des avis positifs et ajout de l'étiquette "1.0" 
    val dataRawPos=sc.textFile(pathDataPos).map(t => (1.0,t));

    // lecture des avis negatifs et ajout de l'étiquette "0.0"
    val dataRawNeg=sc.textFile(pathDataNeg).map(t => (0.0,t));

    // fusion des RDD contenant les avis positifs et les avis négatifs
    val dataRaw = dataRawPos.union(dataRawNeg)

    // suppression des stop words et lemmatisation du texte brut    
    val data = dataRaw.mapPartitions(iter => {
               val pipeline = ParseWikipedia.createNLPPipeline();
               iter.map{ case(label,review) =>
                             (label,ParseWikipedia.plainTextToLemmas(review, stopWords, pipeline))};
           }).cache()

    // création d'un dataframe avec une colonne "label" et une colonne "text" à partir du RDD
    val dataDF = spark.createDataFrame(data).toDF("label", "text");

    dataDF
}

val stopWords = sc.broadcast(ParseWikipedia.loadStopWords("deps/lsa/src/main/resources/stopwords.txt")).value

// lecture des données d'apprentissage
val pathDataPosTrain = "data/input/train/pos"
val pathDataNegTrain = "data/input/train/neg"
val train =buildDataframe(pathDataPosTrain, pathDataNegTrain, stopWords)

// lecture des données de test
val pathDataPosTest = "data/input/test/pos"
val pathDataNegTest = "data/input/test/neg"
val test = buildDataframe(pathDataPosTest, pathDataNegTest, stopWords)

// Creation des transformers HashingTF et IDF
val hashingTF = new HashingTF().setInputCol("text").setOutputCol("rawFeatures").setNumFeatures(4096)
val idf = new IDF().setInputCol("rawFeatures").setOutputCol("features")

// Creation et sauvegarde du dataframe d'apprentissage
val trainTF = hashingTF.transform(train)
val idfModel = idf.fit(trainTF)

val trainTFIDF = idfModel.transform(trainTF)
trainTFIDF.write.parquet("data/output/trainDF_TFIDF")

// Creation et sauvegarde du dataframe de test
val testTF = hashingTF.transform(test)
val testTFIDF = idfModel.transform(testTF)
testTFIDF.write.parquet("data/output/testDF_TFIDF")

