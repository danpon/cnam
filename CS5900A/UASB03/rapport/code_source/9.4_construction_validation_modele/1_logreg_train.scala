import org.apache.spark.sql.SQLContext
import org.apache.spark.ml.classification.LogisticRegression
import org.apache.spark.ml.{Pipeline, PipelineModel}
import org.apache.spark.ml.tuning.{CrossValidator, ParamGridBuilder}
import org.apache.spark.ml.evaluation.BinaryClassificationEvaluator
import org.apache.spark.ml.feature.StandardScaler
import org.apache.spark.ml.param.ParamMap

// dataPath       : emplacement du fichier contenant les données
// logReg         : modele de regression logistique à entrainer
// paramGrid      : grille de (hyper)paramètres utilisée pour grid search
// cvLogRegModelPath : emplacement du fichier ou sera sauvegardé le modèle de régression logistique
def logRegTrain(dataPath: String, logReg: LogisticRegression, paramGrid: Array[ParamMap], cvLogRegModelPath: String) = {
    // Chargement des données d’apprentissage
    val sqlContext = new SQLContext(sc)
    val trainDF = sqlContext.read.parquet("data/output/trainDF")
    val count = trainDF.count()


    // Définition du scaler pour centrer les variables initiales
    val scaler = new StandardScaler().setInputCol("features").setOutputCol("scaledFeatures").setWithStd(false).setWithMean(true)

    // Définition du pipeline (scaler puis régression logistique)
    val pipeline = new Pipeline().setStages(Array(scaler,logReg))

    // Définition de l'instance de CrossValidator : à quel estimateur l'appliquer,
    //  avec quels (hyper)paramètres, combien de folds, comment évaluer les résultats
    val cv = new CrossValidator().setEstimator(pipeline).setEstimatorParamMaps(paramGrid).setNumFolds(5).setEvaluator(new BinaryClassificationEvaluator())

    // Construction et évaluation par validation croisée des modèles correspondant
    //   à toutes les combinaisons de valeurs de (hyper)paramètres de paramGrid
    val cvLogRegModel = cv.fit(trainDF)

    // Afficher les meilleures valeurs pour les (hyper)paramètres
    println("PARAMS : "+cvLogRegModel.getEstimatorParamMaps.zip(cvLogRegModel.avgMetrics).maxBy(_._2)._1)

    // Enregistrement du meilleur modèle
    cvLogRegModel.write.save(cvLogRegModelPath)

    // Calculer les prédictions sur les données d'apprentissage
    val resTrain = cvLogRegModel.transform(trainDF)

    // Calculer et afficher AUC sur données d'apprentissage
    println("AUC : "+ cvLogRegModel.getEvaluator.evaluate(resTrain))

    // Calculer la précision
    resTrain.createOrReplaceTempView("resTrain")
    spark.sql("SELECT count(*)/"+count+ " FROM resTrain  WHERE label == prediction").show()
}

// Initialisation du modèle de régression logistique
val logReg = new LogisticRegression().setFeaturesCol("scaledFeatures").setLabelCol("label")

// Construction de la grille de (hyper)paramètres utilisée pour grid search
// Une composante est ajoutée avec .addGrid() pour chaque (hyper)paramètre à explorer
val paramGrid = new ParamGridBuilder().addGrid(logReg.elasticNetParam, Array(0.0,  0.2,  0.4, 0.6, 0.8, 1)).addGrid(logReg.maxIter, Array(50,100,150,200,250)).addGrid(logReg.regParam, Array(0.01,  0.1,  0.5)).build()


// Apprentissage du modèle
logRegTrain("data/output/trainDF", logReg, paramGrid,"data/output/cv_logreg_model")
