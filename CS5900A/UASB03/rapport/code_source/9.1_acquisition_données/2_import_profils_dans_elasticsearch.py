import json, os, elasticsearch, datetime
from elasticsearch import Elasticsearch
from elasticsearch import helpers

#####################################################################################################################
# Code permettant d’importer en bloc de profils d’utilisateurs Twitter dans une instance Elasticsearch avec l’API bulk
# On crée un index elasticsearch par compte Twitter traitant de la dépression :
#    "depressionarmy", "depressionnote", dbsalliance", "NIMHgov"
#  NB : Un profil utilisateur contient les informations suivantes : (id, name, screen_name, location, description)
#####################################################################################################################

# répertoire contenant les profils d’utilisateurs Twitter au format json
directory_in ="data"

# interface elasticsearch
es = elasticsearch.Elasticsearch()

i=1

print("Start bulk import : ", datetime.datetime.now())

for filename in os.listdir(directory_in):
    if filename.endswith(".json"):
        print(str(datetime.datetime.now())+" : "+filename)
        # si le fichier se termine par ",\n"
        # on remplace les 2 derniers chars par "\n]"
        # de façon à ce qu'il respecte la syntaxe d'un tableau json
        with open(directory_in+"/"+filename, 'rb+') as f:
            f.seek(-2,os.SEEK_END)
            last_chars=f.read().decode('utf-8')
            if(last_chars==',\n'):
                f.seek(-2,2)
                f.truncate()
                f.write('\n]'.encode())
        # extraction du nom de l'index elastic search depuis le nom du fichier
        # ex: "NIMHgov_1555896783124150987.json" ==> "NIMHgov"
        # NB : le téléchargement des profils se fait par tranches de 5000
        # pour un compte twitter avec N abonnées, le téléchargement produit donc N/5000 fichiers
        # le "1555896783124150987" dans le nom de fichier ci-dessus correspond à l’identifiant de la tranche
        pos_fin = filename.rfind("_")
        index_name = filename[:pos_fin].lower()
        # creation du fichier bulk et import dans Elasticsearch
        with open(directory_in+"/"+filename) as json_file_in:
            data_out = json.load(json_file_in)
            nb_data = len(data_out)
            ids = range(i,i+nb_data)
            actions = [
                {
                    "_index" : index_name,
                    "_type" : "profiletwitter",
                    "_id" : ids[j],
                    "_source" : data_out[j]
                }
                for j in range(0, nb_data)
            ]
            helpers.bulk(es,actions)
            i+=nb_data
print("End bulk import : ", datetime.datetime.now())
