#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Sat Aug  3 16:51:42 2019

@author: daniel
"""
import redis
import time
import datetime

# connexion à l'instance Redis locale
r = redis.StrictRedis(host='localhost', port=6379, db=0)
p = r.pubsub()
# abonnement au canal "AAPL_current_price"
p.subscribe('AAPL_current_price')
# variable correspondant au timestamp associé au cours de l’action
# pour simplifier le traitement on se contente d'incrémenter un compteur
t=-1

# boucle sur la réception des messages
while True:
    message = p.get_message()
    if message :
		# NB : le 1er message reçu correspond à une notification
		# de connexion au canal Redis. C'est la raison pour laquelle
		# on vérifie si t>=0 (lors du 1er message t==-1)
        if t >= 0  :
			# affichage du message sur la sortie standard
            print(datetime.datetime.now(),"SUB", message['data'])
        t=t+1
    time.sleep(0.01)
