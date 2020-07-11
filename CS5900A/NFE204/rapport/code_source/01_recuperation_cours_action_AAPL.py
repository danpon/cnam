import time
import os
from yahoofinancials import YahooFinancials
from apscheduler.schedulers.background import BackgroundScheduler

stock="AAPL"
# fichier CSV résultat,ici "AAPL_histo_cours.csv"
outputFile = open(stock+"_histo_cours.csv", "w")

def scrap_stock_current_price():
    # récupération du prix courant de l'action (ici "AAPL")
    # avec le timestamp
    timestamp = str(int(time.time()))
    yahoo_financials = YahooFinancials(stock)
    current_price = str(yahoo_financials.get_current_price())
    # afin de pouvoir importer les données dans un sorted set Redis,
    # chaque ligne du fichier CSV a le format suivant:
    # [timestamp],[prix_action]:[timesamp]
    line= timestamp+","+current_price+":"+timestamp   
    print(line)
    outputFile.write(line)
    outputFile.write("\n")
    outputFile.flush()
    
if __name__ == '__main__':
    # utilisation d'un scheduler qui interroge toutes les 10s
    # le service Yahoo Finance
    scheduler = BackgroundScheduler()
    scheduler.add_job(scrap_stock_current_price, 'interval', seconds=10)
    scheduler.start()
    print('Appuyer sur Ctrl+{0} pour quitter'.format('Break' if os.name == 'nt' else 'C'))

    try:
        # simule une activité afin de maintenir en vie le thread principal
        while True:
            time.sleep(2)
    except (KeyboardInterrupt, SystemExit):
        # pas strictement nécessaire en mode "daemon" mais plus propre
        scheduler.shutdown()
        outputFile.close()