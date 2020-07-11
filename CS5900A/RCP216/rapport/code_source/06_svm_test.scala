import org.apache.spark.sql.SQLContext
import org.apache.spark.ml.tuning.CrossValidatorModel


// dataPath       : emplacement du fichier contenant les données
// cvSVCmodelPath : emplacement du fichier contenant le modèle SVM
def svmTest(dataPath: String, cvSVCmodelPath: String) = {
    // Chargement des données de test
    val sqlContext = new SQLContext(sc)
    val testDF = sqlContext.read.parquet(dataPath) 

    // Chargement du modèle SVM
    val cvSVCmodel =  CrossValidatorModel.load(cvSVCmodelPath)

    // Calculer les prédictions sur les données de test
    val resultats = cvSVCmodel.transform(testDF)

    // Afficher 10 lignes complètes de résultats (sans la colonne features)
    resultats.select("label", "rawPrediction", "prediction").show(10, false)

    // Calculer et afficher AUC sur données de test
    println("AUC : "+cvSVCmodel.getEvaluator.evaluate(resultats))

    // Calculer et afficher la précisions
    resultats.createOrReplaceTempView("resultats")
    spark.sql("SELECT count(*)/25000  FROM resultats  WHERE label == prediction").show()
}

// Evaluation du mdèdle SVM avec les données de test
svmTest("data/output/testDF", "data/output/cvSVCmodel")
svmTest("data/output/testDF_TFIDF", "data/output/cvSVCmodel_TFIDF")
