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
Under ``Step 3``, make sure to enable ‘Auto-assign IP’ and leave the rest as is.
<BR><BR>
![plot of enable_public_ip](../img/posts/idea-to-pitch/enable_public_ip.png)
<BR><BR><BR>
And in ``Step 7`` add a new rule to the security group. Click ``Add Rule`` and choose ``HTTP`` on port 80, this will allow for Internet traffic:
<BR><BR>
![plot of step2_ec2](../img/posts/idea-to-pitch/step2_ec2.png)
<BR><BR><BR>
It should look like the following:
<BR><BR>
![plot of http_ec2](../img/posts/idea-to-pitch/http_ec2.png)
<BR><BR><BR>
Once added, select ``Review and Launch``. We have one more step before reaching the instance - we need create a new ``key pair``. This is a security file that will live on your machine and is required to ‘SSH’ into the instance. I tend to create them and leave them in my downloads. What ever you decided to do, make sure you know where it is as you’ll need to pass a path to it every time you want to connect to it. 
<BR><BR>
![plot of key_pair](../img/posts/idea-to-pitch/key_pair.png)
<BR><BR><BR>
Name it whatever you like and hit the ``Download Key Pair``. Finally select ``Launch Instance`` and we’re ready to go! Keep in mind that whenever you instance is running, you may be charged by Amazon - read the documentation to make sure you’re OK with it. Also, stop the instance when you don’t need to slow down the charges, and terminate it when you don’t need it anymore (i.e. delete it) to stop all charges.

Once the instance is initialized and running, you should see a green light by it:
<BR><BR>
![plot of running_ec2](../img/posts/idea-to-pitch/running_ec2.png)
<BR><BR><BR>
Select the left check-box to access the settings of that specific instance.
<BR><BR>
![plot of instance_ec2](../img/posts/idea-to-pitch/instance_ec2.png)
<BR><BR><BR>

**Connecting to the EC2 Instance**

Select the top ``Connect`` button to get the SSH connection string that enables connections. Follow the instructions if you want to use the Java terminal to connect to the instance. Here, I will be using the terminal on my Mac.
<BR><BR>
![plot of connection_instructions_ec2](../img/posts/idea-to-pitch/connection_instructions_ec2.png)
<BR><BR><BR>


