import com.cloudera.datascience.lsa._
import com.cloudera.datascience.lsa.ParseWikipedia._
import org.apache.spark.ml.feature.Word2Vec

val dataDir="data/input/"

// lecture de l'ensemble des données d'apprentissage
// (avis positifs, avis négatifs et avis non taggés)
val trainPos=sc.textFile(dataDir+"train/pos")
val trainNeg=sc.textFile(dataDir+"train/neg")
val trainUnsup=sc.textFile(dataDir+"train/unsup")

// fusion de l'ensemble des données d'apprentissage en  1 seul RDD : trainAll
val trainAll=trainPos.union(trainNeg).union(trainUnsup)

val stopWords = sc.broadcast(ParseWikipedia.loadStopWords("deps/lsa/src/main/resources/stopwords.txt")).value

// génération du RDD corpus par lemmatisation du texte contenu dans le RDD trainAll
val corpus = trainAll.mapPartitions(iter => {
           val pipeline = ParseWikipedia.createNLPPipeline();
           iter.map{ review  =>  ParseWikipedia.plainTextToLemmas(review, stopWords, pipeline)};
       })

// creation d'un dataframe à partir du RDD corpus
val corpusDF = corpus.toDF("text")

// création du modèle word2vec à partir de corpus 
val word2Vec = new Word2Vec().setInputCol("text").setOutputCol("features").setVectorSize(400).setMinCount(0)
val w2vModel = word2Vec.fit(corpusDF)

// enregistrement du modèle word2vec
w2vModel.save("data/output/w2vModel")


