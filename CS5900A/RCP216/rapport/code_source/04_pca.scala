import org.apache.spark.sql.SQLContext
import org.apache.spark.ml.{Pipeline, PipelineModel}
import org.apache.spark.ml.feature.StandardScaler
import org.apache.spark.ml.feature.PCA
import org.apache.spark.ml.feature.PCAModel

val sqlContext = new SQLContext(sc)
val trainDF = sqlContext.read.parquet("data/output/trainDF") 


// Définition du scaler pour centrer et réduire les variables initiales
val scaler = new StandardScaler().setInputCol("features").setOutputCol("scaledFeatures").setWithStd(true).setWithMean(true)


// Construction et application d'une nouvelle instance d'estimateur PCA
val pca = new PCA().setInputCol("scaledFeatures").setOutputCol("pcaFeatures").setK(3)


// Définition du pipeline (scaler puis PCA)
val pipeline = new Pipeline().setStages(Array(scaler,pca))

// Construction du modèle 
val pipelineModel = pipeline.fit(trainDF)

// Application du « transformateur » pipeline
val resultat = pipelineModel.transform(trainDF).select("pcaFeatures")

// Extraction du modèle PCA à partir du pipeline
val pcaModel=pipelineModel.stages(1).asInstanceOf[PCAModel]

// Affichage de la variance expliquée
pcaModel.explainedVariance

// Sauvegarde des 3 premiers composantes principales dans un fichier texte
resultat.repartition(1).map(v => v.toString.filter(c => c != '[' & c != ']')).write.text("data/output/pcaFeatures")

// Sauvegarde des labels associés dans un autre fichier texte
trainDF.select("label").repartition(1).map(v => v.toString.filter(c => c != '[' & c != ']')).write.text("data/output/pcaLabel")
