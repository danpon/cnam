import tweepy
from tweepy import OAuthHandler
from tweepy import Stream
from tweepy.streaming import StreamListener
import json
import re
import sys
import os
import tablib
import datetime

#######################################################################################
# Code permettant de récupérer dans un flux twitter les profils utilisateurs dont les
# descriptions contiennent les mots clés "happy" ou "optimist"
# Les profils sont exportés dans un fichier Excel
########################################################################################


keywords =["optimist","happy"]
words_re = re.compile("|".join(keywords))

output_directory='results'
if not os.path.isdir(output_directory) :
	os.mkdir(output_directory)

class MyStreamListener(StreamListener):
	counter=0
	data = tablib.Dataset(headers=['id','name','screen_name', 'location','description', 'exclude'])
	dict_users = {}

	# sur réception d'un tweet :
	def on_status(self, status):
		try:
			# vérifie que que le tweet contient la description de l'utilisateur qui l'a émis
			if status.user.description :
				# vérifie que l'utilisateur n'a pas déjà été récupéré
				if not status.user.id in self.dict_users:
					user_description=status.user.description.lower()
					# vérifie que la description de l'utilisateur contient les mots "optimist" ou "happy"
					if words_re.search(user_description):
							# export du profil utilisateur dans un fichier Excel
							self.dict_users[status.user.id]=status.user.id
							col1 = str(status.user.id)
							col2 = status.user.name
							col3 = status.user.screen_name
							col4 = status.user.location
							col5 = status.user.description
							col6 = ' '
							row=(col1,col2,col3,col4,col5,col6)
							self.data.append(row)
							self.counter=self.counter+1
							if (self.counter%100==0):
								print(str(datetime.datetime.now())+" : ",self.counter)
								with open(output_directory+'/users.xlsx', 'wb') as f:
									f.write(self.data.export('xlsx'))
									if(self.counter>=10000):
										sys.exit()
		except Exception as e:
			print(e)

if __name__ == "__main__":
	auth = OAuthHandler("XXXXXXXX", "XXXXXXXX",)
	auth.set_access_token("XXXXXXXX","XXXXXXXX",)
	myStreamListener = MyStreamListener()
	myStream = tweepy.Stream(auth = auth, listener=myStreamListener)
	# l'API twitter  nécessite de filtrer les tweets en précisant un ou plusieurs mots clés.
	# nous définissons le filtre le moins restrictif possible avec le mot clé "the"
	# afin de capter le maximum de tweets
	myStream.filter(languages=["en"], track=["the"])
