import com.cloudera.datascience.lsa._
import com.cloudera.datascience.lsa.ParseWikipedia._
import org.apache.spark.ml.feature.Word2Vec

val dataDir="data/input/"

// lecture des tweets du goupe "depressed"
val tweetsDepressed=sc.textFile(dataDir+"depressed.txt")
// lecture des tweets du goupe "undepressed"
val tweetsUndepressed=sc.textFile(dataDir+"undepressed.txt")

// fusion de l'ensemble des tweets en  1 seul RDD : tweetsAll
val tweetsAll=tweetsDepressed.union(tweetsUndepressed)

val stopWords = sc.broadcast(ParseWikipedia.loadStopWords("deps/lsa/src/main/resources/stopwords.txt")).value

// création du RDD corpus en lemmatisant les tweets
val corpus = tweetsAll.mapPartitions(iter => {
           val pipeline = ParseWikipedia.createNLPPipeline();
           iter.map{ tweet  =>  ParseWikipedia.plainTextToLemmas(tweet, stopWords, pipeline)};
       })

// transformation du RDD corpus en dataframe
val corpusDF = corpus.toDF("text")

// création du modèle word2vec à partir de corpus 
val word2Vec = new Word2Vec().setInputCol("text").setOutputCol("features").setVectorSize(100).setMinCount(0)
val w2vModel = word2Vec.fit(corpusDF)

// enregistrement du modèle word2vec
w2vModel.save("data/output/w2vModel")


