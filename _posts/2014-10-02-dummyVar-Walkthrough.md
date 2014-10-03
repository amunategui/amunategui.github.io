---
layout: post
title: "Brief Walkthrough Of The <B>dummyVars</B> Function From {caret}"
category: Machine Learning
tags: exploring
year: 2014
month: 10
day: 2
published: true
summary: The <B>dummyVars</B> function streamlines the creation of dummy variables by quickly hunting down character and factor variables and transforming them into binaries, with or without full rank.

image: dummyVarWalkthrough/factor4.png
---

As the name implies, the ``dummyVars`` function allows you to create dummy variables - in other words it translates text data into numerical data for modeling purposes.

If you are planning on doing predictive analytics or machine learning and want to use regression or any other modeling technique that requires numerical data, you will need to transform your text data into numbers otherwise you run the risk of leaving a lot of information on the table...

In R, there are plenty of ways of translating text into numerical data. You can do it manually, use a base function, such as **matrix**, or a packaged function like dummyVarfrom the caret package. One of the big advantages of going with the caret package is that it's full of features, including hundreds of algorithms and pre-processing functions. Once your data fits into caret's modular design, it can be run throughdifferent models with minimal tweaking.

Let's look at a few examples of dummy variables. If you have a survey question with 5 categorical values such as very unhappy, unhappy, neutral, happy and very happy.

```r
survey <- data.frame(service=c('very unhappy','unhappy','neutral','happy','very happy'))
print(survey)
```

```
##        service
## 1 very unhappy
## 2      unhappy
## 3      neutral
## 4        happy
## 5   very happy
```
<BR>
You can easily translate this into a sequence of numbers from 1 to 5. Where 3 means neutral and, in the example of a linear model that thinks in fractions, 2.5  means somewhat unhappy, and 4.88 means very happy. So here we successfully transformed this survey question into a continuous numerical scale and do not need to add dummy variables - a simple rank column will do.

```r
survey <- data.frame(service=c('very unhappy','unhappy','neutral','happy','very happy'), rank=c(1,2,3,4,5))
print(survey)
```

```
##        service rank
## 1 very unhappy    1
## 2      unhappy    2
## 3      neutral    3
## 4        happy    4
## 5   very happy    5
```
<BR>
So, the above could easily be used in a model that needs numbers and still represent that data accurately using the 'rank' variable instead of 'service'. **But** this only works in specific situations where you have somewhat linear and continuous-like data. What happens with categorical values such as marital status, gender, alive?
<BR><BR>
Does it make sense to be a quarter female? Or half single? Even numerical data of a categorical nature may require transformation. Take the zip code system. Does thehalf-way point between two zip codes make geographical sense? Because that is how a regression model would use it. 
<BR><BR
It may work in a fuzzy-logic way but it won't help in predicting much; therefore we need a more precise way of translating these values into numbers so that they can be regressed by the model.

```r
library(caret)
# check the help file for more details
?dummyVars
```
<BR>
The **dummyVars** function breaks out unique values from a column into individual columns - if you have 1000 unique values in a column, dummying them will add 1000 new columns to your data set (be careful). Lets create a more complex data frame:

```r
customers <- data.frame(
                id=c(10,20,30,40,50), 
                gender=c('male','female','female','male','female'), 
                mood=c('happy','sad','happy','sad','happy'), 
                outcome=c(1,1,0,0,0))
```
<BR>
And ask the ``dummyVars`` function to dummify it. The function takes a standard R formula: **something ~ (broken down) by something else or groups of other things**. So we simply use **~ .** and the ``dummyVars`` will transform all characters and factors columns (the function never transforms numeric columns) and return the entire data set:

```r
# dummify the data
dmy <- dummyVars(" ~ .", data = customers)
trsf <- data.frame(predict(dmy, newdata = customers))
print(trsf)
```

```
##   id gender.female gender.male mood.happy mood.sad outcome
## 1 10             0           1          1        0       1
## 2 20             1           0          0        1       1
## 3 30             1           0          1        0       0
## 4 40             0           1          0        1       0
## 5 50             1           0          1        0       0
```
<BR>
If you just want one column transform you need to include that column in the formula and it will return a data frame based on that variable only:

```r
customers <- data.frame(
                id=c(10,20,30,40,50), 
                gender=c('male','female','female','male','female'), 
                mood=c('happy','sad','happy','sad','happy'), 
                outcome=c(1,1,0,0,0))

dmy <- dummyVars(" ~ gender", data = customers)
trsf <- data.frame(predict(dmy, newdata = customers))
print(trsf)
```

```
##   gender.female gender.male
## 1             0           1
## 2             1           0
## 3             1           0
## 4             0           1
## 5             1           0
```
<BR>
The ``fullRank`` parameter is worth mentioning here. The general rule for creating dummy variables is to have one less variable than the number of categories present to avoid perfect collinearity (**dummy variable trap**). You basically want to avoid highly correlated variables but it also save space. If you have a factor column comprised of two levels 'male' and 'female', then you don't need to tranform it into two columns, instead, you pick one of the variables and you are either female, if its a **1**, or male if its a **0**.
<BR>
Let's turn on ``fullRank`` and try our data frame again:

```r
customers <- data.frame(
                id=c(10,20,30,40,50), 
                gender=c('male','female','female','male','female'), 
                mood=c('happy','sad','happy','sad','happy'), 
                outcome=c(1,1,0,0,0))

dmy <- dummyVars(" ~ .", data = customers, fullRank=T)
trsf <- data.frame(predict(dmy, newdata = customers))
print(trsf)
```

```
##   id gender.male mood.sad outcome
## 1 10           1        0       1
## 2 20           0        1       1
## 3 30           0        0       0
## 4 40           1        1       0
## 5 50           0        0       0
```
As you can see, it picked male and sad, if you are **0** in both columns, then you are ``female`` and ``happy``.
<BR><BR>
**Things to keep in mind**<BR>
<li>Don't dummy a large data set full of zip codes; you more than likely don't have the computing muscle to add an extra 43,000 columns to your data set.</li>
<li>You can dummify large, free-text columns. Before running the function, look for reapeated words or sentences, only take the top 50 of them and replace the rest with 'others'. This will allow you to use that field without delving deeply into NLP.</li>
<BR><BR>        
[Full source](https://github.com/amunategui/Walkthrough-of-the-dummyVars-Function):

```r
survey <- data.frame(service=c('very unhappy','unhappy','neutral','happy','very happy'))
print(survey)

survey <- data.frame(service=c('very unhappy','unhappy','neutral','happy','very happy'), rank=c(1,2,3,4,5))
print(survey)

library(caret) 

?dummyVars # many options

customers <- data.frame(
        id=c(10,20,30,40,50), 
        gender=c('male','female','female','male','female'), 
        mood=c('happy','sad','happy','sad','happy'), 
        outcome=c(1,1,0,0,0))

dmy <- dummyVars(" ~ .", data = customers)
trsf <- data.frame(predict(dmy, newdata = customers))
print(trsf)
print(str(trsf))

# works only on factors
customers$outcome <- as.factor(customers$outcome)

# tranform just gender
dmy <- dummyVars(" ~ gender", data = customers)
trsf <- data.frame(predict(dmy, newdata = customers))
print(trsf)

# use fullRank to avoid the 'dummy trap'
dmy <- dummyVars(" ~ .", data = customers, fullRank=T)
trsf <- data.frame(predict(dmy, newdata = customers))
print(trsf)
```
<div class="row">   
    <div class="span9 column">
            <p class="pull-right">{% if page.previous.url %} <a href="{{page.previous.url}}" title="Previous Post: {{page.previous.title}}"><i class="icon-chevron-left"></i></a>   {% endif %}   {% if page.next.url %}    <a href="{{page.next.url}}" title="Next Post: {{page.next.title}}"><i class="icon-chevron-right"></i></a>   {% endif %} </p>  
    </div>
</div>

<div class="row">   
    <div class="span9 columns">    
        <h2>Comments Section</h2>
        <p>Feel free to comment on the post but keep it clean and on topic.</p> 
        <div id="disqus_thread"></div>
        <script type="text/javascript">
            /* * * CONFIGURATION VARIABLES: EDIT BEFORE PASTING INTO YOUR WEBPAGE * * */
            var disqus_shortname = 'amunategui'; // required: replace example with your forum shortname
            var disqus_identifier = '{{ page.url }}';
            var disqus_url = 'http://amunategui.github.com{{ page.url }}';
            
            /* * * DON'T EDIT BELOW THIS LINE * * */
            (function() {
                var dsq = document.createElement('script'); dsq.type = 'text/javascript'; dsq.async = true;
                dsq.src = 'http://' + disqus_shortname + '.disqus.com/embed.js';
                (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);
            })();
        </script>
        <noscript>Please enable JavaScript to view the <a href="http://disqus.com/?ref_noscript">comments powered by Disqus.</a></noscript>
        <a href="http://disqus.com" class="dsq-brlink">blog comments powered by <span class="logo-disqus">Disqus</span></a>
    </div>
</div>
 
