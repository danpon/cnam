// répertoire des données initiales
val dataDirInit="data/aclImdb/"
// répertoire des données prétraitées :
val dataDirPreproc="data/input/"

// le prétraitement consiste à merger les fichiers textes de manière à obtenir 
//un seul fichier texte par sous-répertoire (train/po, train/neg, etc ...)
sc.textFile(dataDirInit+"train/pos").coalesce(1).saveAsTextFile(dataDirPreproc+"train/pos")
sc.textFile(dataDirInit+"train/neg").coalesce(1).saveAsTextFile(dataDirPreproc+"train/neg")
sc.textFile(dataDirInit+"train/unsup").coalesce(1).saveAsTextFile(dataDirPreproc+"train/unsup")
sc.textFile(dataDirInit+"test/pos").coalesce(1).saveAsTextFile(dataDirPreproc+"test/pos")
sc.textFile(dataDirInit+"test/neg").coalesce(1).saveAsTextFile(dataDirPreproc+"test/neg")

