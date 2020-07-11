import org.apache.spark.sql.SQLContext
import org.apache.spark.ml.classification.LinearSVC
import org.apache.spark.ml.{Pipeline, PipelineModel}
import org.apache.spark.ml.tuning.{CrossValidator, ParamGridBuilder}
import org.apache.spark.ml.evaluation.BinaryClassificationEvaluator
import org.apache.spark.ml.feature.StandardScaler
import org.apache.spark.ml.param.ParamMap

// dataPath       : emplacement du fichier contenant les données
// linSvc         : estimateur linéaire
// paramGrid      : grille de (hyper)paramètres utilisée pour grid search
// cvSVCmodelPath : emplacement du fichier ou sera sauvegardé le modèle SVM
def svmTrain(dataPath: String, linSvc: LinearSVC, paramGrid: Array[ParamMap], cvSVCmodelPath: String) = {
    // Chargement des données d’apprentissage
    val sqlContext = new SQLContext(sc)
    val trainDF = sqlContext.read.parquet("data/output/trainDF") 

    // Définition du scaler pour centrer les variables initiales
    val scaler = new StandardScaler().setInputCol("features").setOutputCol("scaledFeatures").setWithStd(false).setWithMean(true)

    // Définition du pipeline (sclaer puis SVM linéaire)
    val pipeline = new Pipeline().setStages(Array(scaler,linSvc))

    // Définition de l'instance de CrossValidator : à quel estimateur l'appliquer,
    //  avec quels (hyper)paramètres, combien de folds, comment évaluer les résultats
    val cv = new CrossValidator().setEstimator(pipeline).setEstimatorParamMaps(paramGrid).setNumFolds(5).setEvaluator(new BinaryClassificationEvaluator())

    // Construction et évaluation par validation croisée des modèles correspondant
    //   à toutes les combinaisons de valeurs de (hyper)paramètres de paramGrid
    val cvSVCmodel = cv.fit(trainDF)

    // Afficher les meilleures valeurs pour les (hyper)paramètres
    println("PARAMS : "+cvSVCmodel.getEstimatorParamMaps.zip(cvSVCmodel.avgMetrics).maxBy(_._2)._1)

    // Enregistrement du meilleur modèle
    cvSVCmodel.write.save(cvSVCmodelPath)

    // Calculer les prédictions sur les données d'apprentissage
    val resApp = cvSVCmodel.transform(trainDF)

    // Calculer et afficher AUC sur données d'apprentissage
    println("AUC : "+ cvSVCmodel.getEvaluator.evaluate(resApp))

    // Calculer la précision
    resApp.createOrReplaceTempView("res")
    spark.sql("SELECT count(*)/25000  FROM res  WHERE label == prediction").show()
}

// Définition de l'estimateur SVC linéaire
val linSvc = new LinearSVC().setMaxIter(10).setFeaturesCol("scaledFeatures").setLabelCol("label")

// Construction de la grille de (hyper)paramètres utilisée pour grid search
// Une composante est ajoutée avec .addGrid() pour chaque (hyper)paramètre à explorer
//val paramGrid = new ParamGridBuilder().addGrid(linSvc.regParam, Array(0.02, 0.05, 0.1, 0.2, 0.3, 0.4, 0.5, 0.7,1.0,1.2)).build()

val paramGridW2Vec = new ParamGridBuilder().addGrid(linSvc.regParam, Array(0.01, 0.02, 0.03, 0.04, 0.05,0.06,0.07,0.08,0.09)).addGrid(linSvc.maxIter, Array(10,50,100,150,200)).build()

val paramGridTFIDF = new ParamGridBuilder().addGrid(linSvc.regParam, Array(0.3, 0.35, 0.4, 0.45, 0.5,0.55,0.6,0.65,0.7)).addGrid(linSvc.maxIter, Array(10,50,100,150,200)).build()

// Apprentissage du modèle SVM
svmTrain("data/output/trainDF", linSvc, paramGridW2Vec,"data/output/cvSVCmodel")
svmTrain("data/output/trainDF_TFID",linSvc , paramGridTFIDF,"data/output/cvSVCmodel_TFIDF")
