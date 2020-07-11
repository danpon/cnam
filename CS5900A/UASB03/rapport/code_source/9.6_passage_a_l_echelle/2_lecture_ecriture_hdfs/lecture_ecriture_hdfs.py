
import hdfs

client = hdfs.InsecureClient("http://master.local:50070")


# Crée un répertoire sous la racine HDFS
client.makedirs("/twitter")

# Ecrit un fichier texte ligne à ligne
with client.write("/twitter/tweets_1234.txt", overwrite=True) as writer:
     #  ATTENTION : l'appel à "write()" prend en entrée des bytes et non une string
    writer.write(b"message1\n ")
    writer.write(b"message2\n ")

# Affiche le contenu du répertoire twitter
client.list("/twitter")

# Lit un fichier ligne à ligne
with client.read("/tweets_1234.txt") as reader:
    for line in reader:
        print(line)
