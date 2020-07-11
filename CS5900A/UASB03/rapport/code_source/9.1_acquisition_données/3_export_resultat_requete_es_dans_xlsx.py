import elasticsearch
import tablib
import datetime
import os

###############################################################################################################
# Code permettant d'exécuter une requête Elasticsearh booléenne et d'exporter le résultat dans un fichier Excel
# (la même requête est exécutée sur plusieurs index, on crée un fichier Excel résultat par index)
#############################################################################################################

output_directory='es_search_result'

index_names= [ "depressionarmy" ,"depressionnote" , "dbsalliance", "nimhgov" ]

if not os.path.isdir(output_directory) :
        os.mkdir(output_directory)

es = elasticsearch.Elasticsearch()

for index_name in index_names :
        print(str(datetime.datetime.now())+" query : "+index_name)
        res = es.search(index=index_name, body=
                {
                  "query": {
                    "bool": {
                      "must" : [
                        {
                          "terms": {
                            "description": [
                              "depression",
                              "depressed",
                              "bipolar",
                              "bpd",
                              "survivor",
                              "suicide",
                              "diagnosed",
                              "dysthymia"
                            ]
                          }
                        }
                      ],
                      "must_not" : [
                        {
                          "terms": {
                            "description": [
                              "therapist",
                              "psychiatrist",
                              "organization",
                              "fundation",
                              "NPO",
                              "clinic"
                            ]
                          }
                        }

                      ]
                    }
                  }
                }
        , size=10000)  #Nombre maximum d'enregistrements retournés par la requête

        print("Got %d Hits:" % res['hits']['total']['value'])


        data = tablib.Dataset(headers=['id','name','screen_name', 'location','description', 'exclude'])
        for hit in res['hits']['hits']:
                col1 = hit["_source"]["id"]
                col2 = hit["_source"]["name"]
                col2 = col2.replace('\n', ' ')
                col2 = col2.replace('\t', ' ')
                col3 = hit["_source"]["screen_name"]
                col3 = col3.replace('\n', ' ')
                col3 = col3.replace('\t', ' ')
                col4 = hit["_source"]["location"]
                col4 = col4.replace('\n', ' ')
                col4 = col4.replace('\t', ' ')
                col5 = hit["_source"]["description"]
                col5 = col5.replace('\n', ' ')
                col5 = col5.replace('\t', ' ')
                col6 = ' '
                row=(col1,col2,col3,col4,col5,col6)
                data.append(row)

        with open(output_directory+'/'+index_name+'.xlsx', 'wb') as f:
                f.write(data.export('xlsx'))
