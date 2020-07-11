import os, socket, json, sys, twitter, tweepy
from tweepy import OauthHandler, Stream
from tweepy.streaming import StreamListener

#########################################################################################################
# Code permettant :
# 1) de détecter dans un flux Twitter les utilisateurs postant un message contenant le terme 'depression'
# 2) d'exporter les 50 derniers tweets de ces utilisateurs
# 3) de notifier Spark qu'une classifcation "déprimé/non déprimé" doit être effectuée
#    (en créant pour chaque utilisateur à traiter un fichier contenant l'id de l'utilisateur
#      dans un répertoire scruté par Spark Streamming)
#########################################################################################################

# Listener du flux twitter
class TweetsListener(StreamListener):

	def set_twitter_api(self, twitter_api):
		self.twitter_api = twitter_api

	# répertoire scruté par Spark Streaming
	# les fichier de ce répertoire contiennent uniquement l'id d'un utilisateur sur lesquels on souhaite
	# effectuer la classification
	# la création d'un fichier dans ce répertoire, détecté par Spark Streaming, déclenche la classification
	def set_notifications_directory(self, notifications_directory):
		self.notifications_directory = notifications_directory

	# répertoire contenant les tweets d'utilisateurs sur lesquels la classification doit être appliquée
	def set_tweets_directory(self, tweets_directory):
		self.tweets_directory = tweets_directory

	# cette fonction est appelée quand un utilisateur twitter poste un message contenant le terme "depression"
	# cf. filtrage du flux plus bas : "twitter_stream.filter(languages=["en"], track=['depression'])"
	def on_status(self, status):
		try:
			user_id = str(status.user.id)
			print(user_id)
			tweets = self.twitter_api.GetUserTimeline(user_id=user_id, count=50)
			# on ne prend en compte que les utilisateurs ayant posté au moins 50 messages
			if tweets and len(tweets)==50 :
				data_out = []
				for tweet in tweets:
					text = tweet._json['text'].replace("\n", " ")+"\n"
					data_out.append(text)
				# création dans le répertoire 'tweets' d'un fichier :
				# 1) dont le nom correspond à l'id de l'utilisateur ayant posté le tweet
				# 2) contenant les textes des 50 derniers messages postés par l'utilisateur
				with open(self.tweets_directory+"/"+user_id+".txt", 'w', encoding='utf-8') as text_file_out:
					text_file_out.writelines(data_out)
				# création dans le répertoire 'notifications' d'un fichier contenant uniquement l'id de l'utilisateur
				# pour avertir Spark qu'une classification doit être effectuée
				with open(self.notifications_directory+"/"+user_id, 'w', encoding='utf-8') as f:
					f.write(user_id)
		except Exception as e:
			print(e)

	def on_error(self, status):
		print(status)
		return True

# initialisation du traitement du flux twitter
def captureTweets():
	notifications_directory = "notifications"
	if not os.path.isdir(notifications_directory) :
		os.mkdir(notifications_directory)
	tweets_directory = "tweets"
	if not os.path.isdir(tweets_directory) :
		os.mkdir(tweets_directory)

	#authentification
	auth = OAuthHandler(consumer_key, consumer_secret)
	auth.set_access_token(access_token, access_secret)
	# initialisation du listener
	tweetsListener = TweetsListener()
	tweetsListener.set_twitter_api(twitter.Api(consumer_key="XXXXX",
		consumer_secret="XXXXX",
		access_token_key="XXXXX",
		access_token_secret="XXXXX",
		sleep_on_rate_limit=True))
	tweetsListener.set_notifications_directory(notifications_directory)
	tweetsListener.set_tweets_directory(tweets_directory)
	twitter_stream = Stream(auth,tweetsListener)
	twitter_stream.filter(languages=["en"], track=['depression'])

if __name__ == "__main__":
	captureTweets( )
