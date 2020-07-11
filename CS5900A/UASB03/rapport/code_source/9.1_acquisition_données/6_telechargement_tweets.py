import twitter
import json
import shutil
import sys
import datetime
import os

##################################################################################################################
# Code permettant de télécharger les tweets postés par une liste d'utilisateurs dans des fichiers jsons
# (un fichier par utilisateur)
##################################################################################################################

api = twitter.Api(  consumer_key="xxxxx", consumer_secret="xxxxx", access_token_key="xxxxx",
                    access_token_secret="xxxxx",sleep_on_rate_limit=True)

output_directory = 'tweets'

# récupère l'ensemble des tweets postés par un utilisateur dont l'id est passeé en paramètre
def getUserTweets(api=None, user_id=None):
    print("==> "+str(datetime.datetime.now())+" getUserTweets, user_id=",user_id)
    try:
        tweets = api.GetUserTimeline(user_id=user_id, count=200)
        if not tweets:
            return []
        earliest_tweets = min(tweets, key=lambda x: x.id).id
        while True:
            tweets_partial = api.GetUserTimeline(
                user_id=user_id, max_id=earliest_tweets, count=200
            )
            if not tweets_partial :
                break
            new_earliest = min(tweets_partial, key=lambda x: x.id).id
            if new_earliest == earliest_tweets:
                break
            else:
                earliest_tweets = new_earliest
                print("getting tweets before:", earliest_tweets)
                tweets += tweets_partial
    except Exception as e:
        print(e)
        tweets = []
    return tweets

# sauvegarde l'ensemble des tweets postés par une liste d'utilisateurs dont les
# ids sont passés en paramètre dans des fichiers json (un fichier par utilisateur)
def dumpUsersTweets(str_ids=None):
    for str_id in str_ids:
        id=int(str_id)
        tweets = getUserTweets(api=api, user_id=id)
        if tweets and len(tweets)>=50:
            filename=output_directory+'/'+str_id+'.json'
            print("write file (",filename,")")
            with open(output_directory+'/'+str_id+'.json', 'w+') as f:
                nbTweets = len(tweets)
                f.write('[')
                for i in range(0, nbTweets-1):
                    f.write(json.dumps(tweets[i]._json))
                    f.write(',\n')
                f.write(json.dumps(tweets[nbTweets-1]._json))
                f.write('\n')
                f.write(']')
        else:
            print("Not enough tweets")

def main():
    if not os.path.isdir(output_directory) :
        os.mkdir(output_directory)
    dict_id_count = {}
    # lecture de la liste des ids d'utilisateurs dont on souhaite télécharger les tweets
    # ces ids ont été stockés dans une map (dictionary en python) de façon à éliminer les doublons
    with open('dict_id_count.json') as json_data:
        dict_id_count = json.load(json_data)
    dumpUsersTweets(str_ids=dict_id_count.keys())

if __name__== "__main__":
    main()
