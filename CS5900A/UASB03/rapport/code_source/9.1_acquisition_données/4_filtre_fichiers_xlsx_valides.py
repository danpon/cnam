import datetime
import os
import json

################################################################################
# Code permettant de récupérer dans les fichiers Excels des profils utilisateurs
# les identifiants de ceux qui ont été validés manuellement
# (i.e. lignes  où la colonne exclude n'a pas été cochée avec un "x")
# NB : les identifiants sont stockés dans une map pour éliminer les doublons
# Avant d'être exporté dans un fichier jon
##############################################################################

input_directory  = 'checked_accounts'
output_directory  = 'filtered_results'

if not os.path.isdir(output_directory) :
	os.mkdir(output_directory)

# Map utilisée pour éliminer les doublons
dict_id_count= {}

for filename in os.listdir(input_directory):
	print(str(datetime.datetime.now())+" : "+filename)
	df = pd.read_excel(input_directory+"/"+filename)
	df=df[df['exclude']!='x']
	for row in df.itertuples(index=True):
		id=getattr(row, "id")
		count = 1
		if (id in  dict_id_count) :
			count = dict_id_count[id] +1
		dict_id_count[id]=count
json.dump( dict_id_count, open( output_directory+'/dict_id_count.json', 'w' ))
