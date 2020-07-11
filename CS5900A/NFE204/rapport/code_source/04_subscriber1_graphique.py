#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Sat Aug  3 16:51:42 2019

@author: daniel
"""
import redis
import time
import matplotlib.pyplot as plt
from drawnow import drawnow

def makeFig():
	# dessine la figure
    plt.plot(xList,yList)
    plt.axis([0,625,195,205])

# rend la figure interactive
plt.ion()
# crée la figure			
fig=plt.figure() 	

# liste des abscisses (timestamp)
xList=list()
# liste des ordonnées (cours de l'action AAPL)
yList=list()

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
            y = float(message['data'])
			# ajoute la nouvelle donnée dans les cordonnées des points
            xList.append(t)
            yList.append(y)
			# actualise la figure contenant la courbe de tendance
            drawnow(makeFig)
        t=t+1    
    time.sleep(0.01)
