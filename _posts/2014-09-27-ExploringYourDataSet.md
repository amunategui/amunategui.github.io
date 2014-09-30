---
layout: post
title: Using Correlations To Understand Your Data
category: Exploring Data
tags: exploring
year: 2014
month: 9
day: 27
published: true
summary: A great way to explore new data is to run a pairwise correlation matrix against it. This will pair every combination of your variables and measure the correlations between them.
image: correlations/unnamed-chunk-9.png
---

A great way to explore new data is to run a pairwise correlation matrix against it. This will pair every combination of your variables and measure the correlations between them. For those that aren't familiar with the correlation coefficient, it is simply a measure of similarity between two vectors of numbers. The measure value can range between -1 and 1, where 1 is perfectly correlated, and -1 is perfectly inversly correlated. A 0 measure means that there are no correlation between both sets of values. 

To help us understand this process, let's download the [adult.data set](https://archive.ics.uci.edu/ml/datasets/Adult) from the UCI Machine Learning Repository. This data is based on the 1994 Census and attempts to predict those with income exceeding $50K/year:

```r
library(RCurl) # download https data
urlfile <- 'https://archive.ics.uci.edu/ml/machine-learning-databases/adult/adult.data'
x <- getURL(urlfile, ssl.verifypeer = FALSE)
adults <- read.csv(textConnection(x), header=F)

# if the above getURL command fails, try this:
# adults <-read.csv('https://archive.ics.uci.edu/ml/machine-learning-databases/adult/adult.data', header=F)
```
<BR>
We fill in the missing headers for the UCI set and cast the outcome variable 'income' to a binary format of 1 and 0:

```r
names(adults)=c('age','workclass','fnlwgt','education','educationNum',
                'maritalStatus','occupation','relationship','race',
                'sex','capitalGain','capitalLoss','hoursWeek',
                'nativeCountry','income')

adults$income <- ifelse(adults$income==' <=50K',1,0)
```
<BR>
We load the **caret** package to dummify (binarize) all factor variables as the correlation function only accepts numerical values:


```r
dmy <- dummyVars(" ~ .", data = adults)
adultsTrsf <- data.frame(predict(dmy, newdata = adults))
```
<BR>
We borrow two very useful functions from [Stephen Turner](https://gist.github.com/stephenturner/3492773): **cor.prob** and **flattenSquareMatrix**. **cor.prob** will create a correlation matrix along with <i>p</i>-values and **flattenSquareMatrix** will flatten all the combinations from the square matrix into a data frame of 4 columns made up of row names, column names, the correlation value and the <i>p</i>-value:

```r
corMasterList <- flattenSquareMatrix (cor.prob(adultsTrsf))
print(head(corMasterList,10))
```

```
##                         i                       j       cor         p
## 1                     age            workclass...  0.042627 1.421e-14
## 2                     age  workclass..Federal.gov  0.051227 0.000e+00
## 3            workclass...  workclass..Federal.gov -0.042606 1.454e-14
## 4                     age    workclass..Local.gov  0.060901 0.000e+00
## 5            workclass...    workclass..Local.gov -0.064070 0.000e+00
## 6  workclass..Federal.gov    workclass..Local.gov -0.045682 2.220e-16
## 7                     age workclass..Never.worked -0.019362 4.759e-04
## 8            workclass... workclass..Never.worked -0.003585 5.178e-01
## 9  workclass..Federal.gov workclass..Never.worked -0.002556 6.447e-01
## 10   workclass..Local.gov workclass..Never.worked -0.003843 4.880e-01
```
<BR>
This final format allows you to easily order the pairs however you want - for example, by those with the highest absolute correlation value:
```r
corList <- corMasterList[order(-abs(corMasterList$cor)),]
print(head(corList,10))

```
```
##                                      i                            j        cor p
## 1953                       sex..Female                    sex..Male -1.0000000 0
## 597                       workclass...                occupation...  0.9979854 0
## 1256 maritalStatus..Married.civ.spouse        relationship..Husband  0.8932103 0
## 1829                       race..Black                  race..White -0.7887475 0
## 527  maritalStatus..Married.civ.spouse maritalStatus..Never.married -0.6448661 0
## 1881             relationship..Husband                  sex..Female -0.5801353 0
## 1942             relationship..Husband                    sex..Male  0.5801353 0
## 1258      maritalStatus..Never.married        relationship..Husband -0.5767295 0
## 1306 maritalStatus..Married.civ.spouse  relationship..Not.in.family -0.5375883 0
## 497                                age maritalStatus..Never.married -0.5343590 0
```

The top correlated pairs as seen above won't be of much use when they're from the same factor. We need to process this a little further to be of practical use. We create a single vector of variable names (using the original names, not the dummified ones) by filtering those with an absolute correlation of 0.2 against or higher against our outcome variable of 'income':

```r
selectedSub <- subset(corList, (abs(cor) > 0.2 & j == 'income'))
bestSub <-  sapply(strsplit(as.character(selectedSub$i),'[.]'), "[", 1)
bestSub <- unique(bestSub)
```
Finally we plot the highly correlated pairs using the **psych** packages **pair.panels** plot (this can be done on the original data as **pair.panels** can handle factor and character variables):
<BR>



```r
pairs.panels(adults[c(bestSub, 'income')])
```

![plot of chunk unnamed-chunk-9](../img/posts/correlations/unnamed-chunk-9.png) 
<BR>
[Full Source](https://github.com/amunategui/Exploring-Data-With-Correlations/blob/master/Correlations.R):

```r
library(RCurl) # download https data
urlfile <- 'https://archive.ics.uci.edu/ml/machine-learning-databases/adult/adult.data'
x <- getURL(urlfile, ssl.verifypeer = FALSE)
adults <- read.csv(textConnection(x), header=F)

# if the above getURL command fails, try this:
# adults <-read.csv('https://archive.ics.uci.edu/ml/machine-learning-databases/adult/adult.data', header=F)

names(adults)=c('age','workclass','fnlwgt','education','educationNum',
                'maritalStatus','occupation','relationship','race',
                'sex','capitalGain','capitalLoss','hoursWeek',
                'nativeCountry','income')

adults$income <- ifelse(adults$income==' <=50K',1,0)

library(caret)
dmy <- dummyVars(" ~ .", data = adults)
adultsTrsf <- data.frame(predict(dmy, newdata = adults))

## Correlation matrix with p-values. See http://goo.gl/nahmV for documentation of this function
cor.prob <- function (X, dfr = nrow(X) - 2) {
        R <- cor(X, use="pairwise.complete.obs")
        above <- row(R) < col(R)
        r2 <- R[above]^2
        Fstat <- r2 * dfr/(1 - r2)
        R[above] <- 1 - pf(Fstat, 1, dfr)
        R[row(R) == col(R)] <- NA
        R
}
 
## Use this to dump the cor.prob output to a 4 column matrix
## with row/column indices, correlation, and p-value.
## See StackOverflow question: http://goo.gl/fCUcQ
flattenSquareMatrix <- function(m) {
        if( (class(m) != "matrix") | (nrow(m) != ncol(m))) stop("Must be a square matrix.")
        if(!identical(rownames(m), colnames(m))) stop("Row and column names must be equal.")
        ut <- upper.tri(m)
        data.frame(i = rownames(m)[row(m)[ut]],
                   j = rownames(m)[col(m)[ut]],
                   cor=t(m)[ut],
                   p=m[ut])
}

corMasterList <- flattenSquareMatrix (cor.prob(adultsTrsf))
print(head(corMasterList,10))

corList <- corMasterList[order(-abs(corMasterList$cor)),]
print(head(corList,10))

corList <- corMasterList[order(corMasterList$cor),]
selectedSub <- subset(corList, (abs(cor) > 0.2 & j == 'income'))
bestSub <-  sapply(strsplit(as.character(selectedSub$i),'[.]'), "[", 1)
bestSub <- unique(bestSub)

library(psych)
pairs.panels(adults[c(bestSub, 'income')])
```
<script src="https://github.com/amunategui/SMOTE-Oversample-Rare-Events/blob/master/SMOTE_sample.R"></script>

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
            var disqus_url = 'http://erjjones.github.com{{ page.url }}';
            
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
