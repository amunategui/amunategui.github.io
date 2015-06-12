---
layout: post
title: "From the Idea to the Pitch: Hosting your Python Program with Flask and Amazon Web Services"
category: Machine Learning
tags: modeling python
year: 2015
month: 06
day: 12
published: true
summary: "The idea behind this walkthrough is to demonstrate how easy it is to transform an idea into a web application. This is for those that want to quickly pitch their application to the world without getting bogged down by technical details. This is for the weekend warrior. If the application is a success, people with real skills will be brought in to do the job right, in the meantime we want it fast, cheap and easy. We'll use Python, Flask, and Amazon Cloud Services EC2"
image: idea-to-pitch/flask.png
---

<BR><BR>

The idea behind this walkthrough is to demonstrate how easy it is to transform an idea into a web application. This is for those that want to quickly pitch their application to the world without getting bogged down by technical details. This is for the weekend warrior. If the application is a success, people with real skills will be brought in to do the job right, in the meantime we want it fast, cheap and easy. We'll use Python, Flask, and Amazon Cloud Services EC2.

I will present a project idea, use <b>Python</b> to execute it, create an <b>AWS EC2</b> instance with <a href='http://flask.pocoo.org' target='_blank'>Flask</a> to host it. Even though everything here is relatively simple, there is a lot of steps and you don’t want to miss any of them - take you time, have fun, when in doubt start again, and, most importantly, think about the possibilities!

<BR>
**Pagiarism Defender - A Python Application**
Ok, so I have a Python project that I want to push out on the web. Let's start by analyzing and running it locally.

```r
# sudo apt-get install python-lxml
from lxml import html
import requests, time
# sudo pip install -U nltk
from nltk.tokenize.punkt import PunktSentenceTokenizer, PunktParameters 

punkt_param = PunktParameters()
sentence_splitter = PunktSentenceTokenizer(punkt_param)
sentences = sentence_splitter.tokenize(text_to_filter)
probability_of_plagiarism = 0

for a_sentence in sentences:
    print (a_sentence)
    time.sleep(0.3)
    the_term = urllib2.quote('+' + '"' + a_sentence + '"')
    page = requests.get('https://www.bing.com/search?q='+the_term)
    if (not "No results found for" in page.text):
        probability_of_plagiarism += 1

print('Probability of plagiarism: ' + str((probability_of_plagiarism / len(sentences)) * 100) + '%')

```

This application is very simple, it takes as impout some text (``text_to_filter``), splits it into sentences using <a = href='http://www.nltk.org/' target='_blank'>Natural Language Toolkit (NLTK)</a>, and finally sends each to the Bing search engine for matches. It surrounds each sentence with quotes to find exact matches, if a match is found, then that sentence is deemed plagiarzied. It does so for all sentences and returns the mean as a plagiarizm score. 

Try it out on the first line of Moby Dick:

<quote>"Call me Ishmael. Some years ago - never mind how long precisely - having little or no money in my purse, and nothing particular to interest me on shore, I thought I would sail about a little and see the watery part of the world."</quote>

This may not scale too well as Bing would quickly get upset, but for our purposes it is fine. Let's push this out onto the web and get some exposure.


**Amazon Web Services - Home Away from Home**
Now that we have our web application ready to go, we need the tools to serve it out to the world. We’ll start with our <a href='http://aws.amazon.com/' target='_blank'>Amazon Web Service EC2 instance</a>. You will need an AWS account to access the site. 

First, log into the AWS console:

![plot of logging_on_AWS](../img/posts/idea-to-pitch/logging_on_AWS.png) 


 