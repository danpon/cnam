# affiche l’heure de début d’insertion des données (avec une précision à la ms)
date +"%T.%3N" 

# insère les données du fichier AAPL.CSV en masse avec resids-cli-pipe
# chaque ligne du fichier AAPL_histo_cours.csv est transformé en une instruction Redis – ex :
# CSV : 					"1564764872,1564764872"
# Sortie du script Perl :	"ZADD AAPL_histo_cours 1564764872 203.84:1564764872" 
awk -F, 'BEGIN {OFS=","} 
{ print "ZADD AAPL_histo " $1 " " $2 ":" $1}' AAPL_histo_cours.csv | redis-cli --pipe

# affiche l’heure de fin d’insertion des données
date +"%T.%3N" 