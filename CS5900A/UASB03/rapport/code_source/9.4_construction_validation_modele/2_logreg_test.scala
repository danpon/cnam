import org.apache.spark.sql.SQLContext
import org.apache.spark.ml.tuning.CrossValidatorModel


// dataPath       : emplacement du fichier contenant les données
// cvLogRegModelPath : emplacement du fichier contenant le modèle de régression logistique
//                     obtenu par validation croisée    
def logRegTest(dataPath: String, cvLogRegModelPath: String) = {
    // Chargement des données de test
    val sqlContext = new SQLContext(sc)
    val testDF = sqlContext.read.parquet(dataPath)
    val count = testDF.count()

    // Chargement du modèle SVM
    val cvLogRegModel =  CrossValidatorModel.load(cvLogRegModelPath)

    // Calculer les prédictions sur les données de test
    val resultats = cvLogRegModel.transform(testDF)

    // Afficher 10 lignes complètes de résultats (sans la colonne features)
    // la colonne "probability" contient un vecteur : 
    // [probabilité label = 0 (undepressed), probabilité label = 1 (depressed)]
    resultats.select("label", "probability", "prediction").show(10, false)

    // Calculer et afficher AUC sur données de test
    println("AUC : "+cvLogRegModel.getEvaluator.evaluate(resultats))

    // Calculer et afficher la précisions
    resultats.createOrReplaceTempView("resultats")
    spark.sql("SELECT count(*)/"+count+ " FROM resultats  WHERE label == prediction").show()
   
    //Afficher un résumé détaillé
   resultats.summary().show()
}

// Evaluation du mdèdle SVM avec les données de test
logRegTest("data/output/testDF", "data/output/cv_logreg_model")

