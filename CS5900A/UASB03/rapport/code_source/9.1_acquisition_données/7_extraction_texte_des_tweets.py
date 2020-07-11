import os, json, datetime

directory_in ="tweets"
directory_out="tweets_text"

#############################################################################
# Code permettant l'extraction du texte des tweets.
# A partir de  chaque fichier json (contenant l'intégralité des tweets d'un utilisateur plus des informations connexes),
# on génère un fichier contenant uniquement le texte des messages
# (avec une ligne par message)
#############################################################################

def main():
    if not os.path.isdir(directory_out) :
        os.mkdir(directory_out)
    print("Start text extraction : ", datetime.datetime.now())
    for filename in os.listdir(directory_in):
        if filename.endswith(".json"):
            data_out = []
            with open(directory_in+"/"+filename) as json_file_in:
                data_in = json.load(json_file_in)
                for elt_json_in in data_in:
                    # regroupe le texte du tweet sur une seule ligne
                    text=elt_json_in['text'].replace("\n", " ")+"\n"
                    data_out.append(text)
            with open(directory_out+"/"+filename.replace(".json",".txt"),"w") as text_file_out:
                text_file_out.writelines(data_out)
    print("End text extraction : ", datetime.datetime.now())

if __name__== "__main__":
    main()
