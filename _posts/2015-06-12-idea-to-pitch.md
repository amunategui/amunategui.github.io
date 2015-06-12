---
layout: post
title: "Going from the Idea to the Pitch: Hosting your Python Application with Flask and Amazon Web Services"
category: Machine Learning
tags: modeling python
year: 2015
month: 06
day: 12
published: true
summary: "The idea behind this walkthrough is to demonstrate how easy it is to transform an idea into a web application. This is for those that want to quickly pitch their application to the world without getting bogged down by technical details. This is for the weekend warrior. If the application is a success, people with real skills will be brought in to do the job right, in the meantime we want it fast, cheap and easy. We'll use Python, Flask, and Amazon Cloud Services EC2"
image: idea-to-pitch/flask.png
---

In this project, I take an idea coded in <b>Python</b>, create an <b>AWS EC2</b> instance, and use <b><a href='http://flask.pocoo.org' target='_blank'>Flask</a></b> to share it with the world. Even though everything here is relatively simple, there are a lot of steps and you don’t want to miss any - take you time, have fun, when in doubt start again, and, most importantly, think about the possibilities for your own work!

<BR><BR>
<h2>Pagiarism Defender - A Python Application</h2>
<BR><BR>
OK, so I have a Python project that I want to push out on the web. Let's start by analyzing and running it locally. It should be straightforward; it takes some text as input (``text_to_filter``), splits it into sentences using <a = href='http://www.nltk.org/' target='_blank'>Natural Language Toolkit (NLTK)</a>, and sends it to the Bing search engine for matches. It surrounds each sentence with quotes to <b>only</b> find exact matches. If a match is found, then that sentence is deemed plagiarized and a counter is incremented. It does so for all sentences and returns the mean of the counter as a plagiarism score. 

```r
# sudo apt-get install python-lxml
from lxml import html
import requests, time
# sudo pip install -U nltk
from nltk.tokenize.punkt import PunktSentenceTokenizer, PunktParameters 

# Try it out on the first lines of Moby Dick:
text_to_check = "Call me Ishmael. Some years ago - never mind how long precisely - having little or no money in my purse, and nothing particular to interest me on shore, I thought I would sail about a little and see the watery part of the world."

punkt_param = PunktParameters()
sentence_splitter = PunktSentenceTokenizer(punkt_param)
sentences = sentence_splitter.tokenize(text_to_check)
probability_of_plagiarism = 0

for a_sentence in sentences:
    print(a_sentence)
    time.sleep(0.3)
    the_term = urllib2.quote('+' + '"' + a_sentence + '"')
    page = requests.get('https://www.bing.com/search?q='+the_term)
    if (not "No results found for" in page.text):
        probability_of_plagiarism += 1;

print('Probability of plagiarism: ' + str((probability_of_plagiarism / len(sentences)) * 100) + '%')

```
It correctly determined that the Moby Dick text passed to the function is plagiarized:

```r
In [151]: print('Probability of plagiarism: ' + str((probability_of_plagiarism / len(sentences)) * 100) + '%')
Probability of plagiarism: 100%
```

This may not scale too well as Bing would quickly get upset, but for our purposes it is fine. Let's push this out onto the web and get some exposure.

<BR><BR>
<h2>Amazon Web Services - Home Away from Home</h2>
<BR><BR>
Now that we have our web application ready to go, we need the tools to serve it out to the world. We’ll start with our <a href='http://aws.amazon.com/' target='_blank'>Amazon Web Service EC2 instance</a>. You will need an AWS account to access the site. Even though this is all very simple, there are many of these simple steps; if you miss one, it will not work....

**AWS Console**<br>
First, log into the AWS console:
<BR><BR>
![plot of logging_on_AWS](../img/posts/idea-to-pitch/logging_on_AWS.png) 
<BR><BR>
**VPC**<br>
Select VPC:
<BR><BR>
![plot of choosing_vpc](../img/posts/idea-to-pitch/choosing_vpc.png)
<BR><BR>
A virtual private connection (VPC) will determine who and what gets to access our site. We will use the wizard and content ourselves with only on VPC. In an enterprise-level application, you will want at least 4, 2 to be private and run your database, and two to be public and hold your web-serving application. By duplicating the private and public VPCs you can benefit from fail-over and load balancing tools. By keeping things simple, we’ll get our instance working in just a few clicks, seriously!

Start the wizard:
<BR><BR>
![plot of choosing_vpc](../img/posts/idea-to-pitch/vpc_wizard.png)
<BR><BR><BR>
Start the wizard and select ‘VPC with a Single Public Subnet':
<BR><BR>
![plot of choosing_vpc](../img/posts/idea-to-pitch/vpc_wizard_2.png)
<BR><BR><BR>
Most of the defaults are fine except add a name under ``VPC name`` and select ``Public subnet`` under ``Add endpoints for S3 to you subnets``:
<BR><BR>
![plot of choosing_vpc](../img/posts/idea-to-pitch/vpc_wizard_3.png)
<BR><BR><BR>


**EC2**<BR>
VPC is done, let’s now create our EC2 instance - this is going to be our new machine. Click on the orange cube in the upper left corner of the page. From the ensuing menu, choose the first option, ``EC2``

<BR><BR>
![plot of EC2](../img/posts/idea-to-pitch/EC2.png)
<BR><BR><BR>
Then ``Create Instance``...
<BR><BR>
![plot of EC2](../img/posts/idea-to-pitch/EC2_create_instance.png)
<BR><BR><BR>
We’ll select the free eligible tier <a href='http://www.ubuntu.com/' target='_blank'>Ubuntu</a> box (may not always be free, check if it applies to you). 
<BR><BR>
![plot of ec2_ubuntu](../img/posts/idea-to-pitch/ec2_ubuntu.png)
<BR><BR><BR>
Go with defaults and click ``Next: Configure Instance Details``
<BR><BR>
![plot of ubuntu_defaults](../img/posts/idea-to-pitch/ubuntu_defaults.png)
<BR><BR><BR>



 