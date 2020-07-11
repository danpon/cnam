#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Sat Aug  3 16:50:56 2019

@author: daniel
"""
import redis
import csv
import datetime
import time

# connexion à l'instance Redis locale
queue = redis.StrictRedis(host='localhost', port=6379, db=0)
# création du canal sur lequel seront diffusés les évolutions
# du cours de l'action AAPL (lues dans le fichier "AAPL_histo_cours.csv")
channel = queue.pubsub()

# lecture ligne du fichier csv :
# pour chaque ligne lue (correspondant à la cotation de l'action AAPL
# à un instant donné), un message est envoyé sur le canal Redis
with open('AAPL.csv') as csvfile:
    readCSV = csv.reader(csvfile, delimiter=',')
    for row in readCSV:
        # row est de la forme :
        #    ['timestamp', 'price']
        # ex :
        #    ['1564771092', '203.8179']
        price = row[1]
        print(datetime.datetime.now(),"PUB", price)
		# envoi du message sur le canal "AAPL_current_price"
		# NB : on envoie uniquemnt le prix de l'action pas le timestamp.
		# Le but est de simuler un système diffusant le cours instantané de l'action
		# en temps réel.
        queue.publish('AAPL_current_price', price)
        time.sleep(0.01)

while 1:
    time.sleep(1000)
