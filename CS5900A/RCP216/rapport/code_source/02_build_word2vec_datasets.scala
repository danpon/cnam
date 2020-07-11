import com.cloudera.datascience.lsa._
import com.cloudera.datascience.lsa.ParseWikipedia._
import org.apache.spark.ml.feature.Word2Vec
import org.apache.spark.ml.feature.Word2VecModel

// pathDataPos : emplacement des avis positifs
// pathDataNeg : emplacement des avis négatifs
// stopWords   : collection de stop words
// w2vModel    : modèle WOrd2Vec
// outputFile  : fichier parquet contenant le dataframe résultat
def buildDataframe(pathDataPos: String, pathDataNeg : String, stopWords:Set[String],w2vModel: Word2VecModel, outputFile: String) = {

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
    val dataDF = spark.createDataFrame(data).toDF("label", "text")

    // application du modèle word2vec au texte :
    // ceci se traduit par la création d'un nouveau dataframe
    // comportant une colonne "features"
    // représentant le texte sous forme vectorielle     
    val dataFeaturesDF = w2vModel.transform(dataDF)

    // export du dataframe résultat sous forme d'un fichier parquet
    dataFeaturesDF.write.parquet(outputFile)

}


val stopWords = sc.broadcast(ParseWikipedia.loadStopWords("deps/lsa/src/main/resources/stopwords.txt")).value
val w2vModel = Word2VecModel.load("data/output/w2vModel")

// lecture des données d'apprentissage
val pathDataPosTrain = "data/input/train/pos"
val pathDataNegTrain = "data/input/train/neg"
val outputFileTrain  = "data/output/trainDF"

buildDataframe(pathDataPosTrain, pathDataNegTrain, stopWords, w2vModel, outputFileTrain)

// lecture des données de test
val pathDataPosTest = "data/input/test/pos"
val pathDataNegTest = "data/input/test/neg"
val outputFileTest  = "data/output/testDF"

buildDataframe(pathDataPosTest, pathDataNegTest, stopWords, w2vModel, outputFileTest)

