import twitter
import json
import datetime

#####################################################################################################################
# code permettant d'exporter dans des fichiers json une liste de profils d’utilisateurs twitter
# (id, name, screen_name, location, description) abonnés à des comptes traitant de la dépression
#####################################################################################################################

# Wrapper python de l’API twitter
api = twitter.Api(	consumer_key= "XXXXX",consumer_secret = "XXXXX", access_token_key = "XXXXX",
				access_token_secret = "XXXXX",sleep_on_rate_limit=True)

# liste des comptes twitters ont on souhaite exporter les abonnés
twitter_accounts_about_mental_health = [
	{"id" : "3093201981", "name":"depressionarmy" },	{"id" : "862029310470877185", "name":"depressionnote" },
	{"id" : "94458238", "name":"dbsalliance" }, 		{"id" : "39250316", "name":"NIMHgov" }]

# écrit sur une ligne d’un fichier json un résumé (id, nom, decription,…) du profil twitter de l'utilisateur dont l'id est
# passé en entrée
def write_user_profile(file=None,user_id=None,end_of_line=' },\n'):
    try:
        user_profile= api.GetUser(user_id=user_id)
        if not user_profile.protected:
            file.write('{ "id" : '+json.dumps(user_profile.id_str)+', ')
            file.write('"name" : '+json.dumps(user_profile.name)+', ')
            file.write('"screen_name" : '+json.dumps(user_profile.screen_name)+', ')
            file.write('"location" : '+json.dumps(user_profile.location)+', ')
            file.write('"description" : '+json.dumps(user_profile.description)+end_of_line)
    except Exception as e:
        print(e)

# exporte dans un fichier json, les profils twitter d'une liste d'utilisateurs
def dump_users_profiles(filename=None,user_ids=None):
    print(str(datetime.datetime.now())+" write file : "+filename)
    nb_users = len(user_ids)
    if nb_users==0:
        print("    empty file")
        return
    with open('data/'+filename, 'w+') as f:
        f.write('[\n')
        for i in range(0, nb_users - 1):
            user_id = user_ids[i]
            write_user_profile(file=f,user_id=user_id)
        user_id = user_ids[nb_users - 1]
        write_user_profile(file=f,user_id=user_id,end_of_line=' }\n]')

# récupère les profils d'utilisateurs abonnés à un compte twitter spécifié en entrée et les exporte dans des fichiers json
# (la récupération se fait par tranches de 5000 profils, chaque tranche est stockée dans un fichier distinct)
def dump_followers_profiles(account=None):
    cursor=-1
    results = api.GetFollowerIDsPaged(user_id=account["id"],cursor=cursor)
    cursor =results[0]
    follower_ids=results[2]
    filename = account["name"]+"_"+str(cursor)+".json"
    dump_users_profiles(filename=filename,user_ids=follower_ids)
    while cursor>0:
        results = api.GetFollowerIDsPaged(user_id=account["id"],cursor=cursor)
        cursor = results[0]
        follower_ids=results[2]
        filename = account["name"]+"_"+str(cursor)+".json"
        dump_users_profiles(filename=filename,user_ids=follower_ids)

# parcourt une liste de compte twitters, et pour chacun d'eux exporte dans des fichiers json la liste de ses abonnés
def main():
    for account in twitter_accounts_about_mental_health:
        print("==> "+str(datetime.datetime.now())+' dump_followers_profiles("',account["name"],'")')
        try:
            dump_followers_profiles(account)
        except Exception as e:
            print(e)

if __name__== "__main__":
    main()
