#!/usr/bin/env python
# -*- coding: utf-8 -*-

import tweepy
import json
import pandas as pd
import geojson
import urllib.request
import feedparser
import csv
import geograpy
import nltk
nltk.download('punkt')
nltk.download('averaged_perceptron_tagger')
nltk.download('maxent_ne_chunker')
nltk.download('words')

# Basis of every application

consumer_key = "MrGSDFEOuDd8ZcpxDtiWgms2P"
consumer_secret = "J5mTlAJgzMhBr2QeAVgz0t5eY5vLILtPdUEhFiqpxi3gY7Faf3"
access_token = "1172181580556713984-BfpmLglqt5NGVXZL8jYJ6jFB5Uvzmb"
access_token_secret = "TpvhX7ETKV9mPcE95SDBfueqLy3TpGrU3iFCiA6QzXRYm"

auth = tweepy.OAuthHandler(consumer_key, consumer_secret)
auth.set_access_token(access_token, access_token_secret)
api = tweepy.API(auth)

# ################ EARTHQUAKE ##########################

with urllib.request.urlopen(
        'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/significant_month.geojson') as url:
    temp = url.read()
    earthquakeData = geojson.loads(temp)

LONG = earthquakeData['features'][0]['geometry']['coordinates'][0]
LAT = earthquakeData['features'][0]['geometry']['coordinates'][1]
print(LAT)
print(LONG)
maxRange = 20
num_results = 50

# ##################### RSS ####################

wordBank = ['bomb', 'explosion', 'protest', 'war',
            'port delay', 'port closure', 'hijack',
            'tropical storm', 'tropical depression']
RSSUrls = []
posts = []


def contains_wanted(in_str):
    # returns true if the in_str contains a keyword
    # we are interested in. Case-insensitive
    for wrd in wordBank:
        if wrd in in_str:
            return True
    return False


rss = pd.read_csv('RSSfeed2019.csv')
# print(rss.head())

feeds = []  # list of feed objects
for url in rss['URL'].head(5):
    feeds.append(feedparser.parse(url))
    # print(feeds)

posts = []  # list of posts [(title1, link1, summary1), (title2, link2, summary2) ... ]
for feed in feeds:
    for post in feed.entries:
        if hasattr(post, 'summary'):
            posts.append((post.title, post.link, post.summary))
        else:
            posts.append((post.title, post.link))
            

df = pd.DataFrame(posts, columns=['title', 'link', 'summary'])

mask = df['summary'].str.contains(rf"\b{'|'.join(wordBank)}\b", case=False) | \
       df['title'].str.contains(rf"\b{'|'.join(wordBank)}\b", case=False)

# extract titles
titles = df['title'].values

# print them
for title in titles[mask]:
    hits = df[mask]

urls = hits['link'].values

for url in urls:
    places = (geograpy.get_place_context(url=url))
    print(places.country_regions, "\n", places.country_cities, "\n", places.address_strings, "\n",
          places.country_mentions, "\n", places.city_mentions, "\n")


hits.to_csv('myfile.txt', sep=' ', mode='w')


# Certain user Tweets
# name = "AuroraIntel"
# tCount = 20
# aurora_tweets = api.user_timeline(id=name, count=tCount)
# for tweet in aurora_tweets:
#    print(tweet.text)

query = "earthquake"
language = "en"
tweetCount = 50
results = api.search(q=query,
                     geocode="%f,%f,%dmi" % (LAT, LONG, maxRange), lang=language, count=tweetCount)

"""for idx, tweet in enumerate(results):
    # small mode error - append vs write
     print(idx, tweet.user.screen_name, tweet.created_at,
          "Tweeted: ", tweet.text, "\n")
          # file=open("output.txt", "a", encoding="utf-8"))
"""
