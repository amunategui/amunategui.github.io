---
layout: post
title: Reducing High Dimensional Data with <B>Principle Component Analysis</B> (PCA) and <b>{prcomp}</b>
category: Machine Learning
tags: exploring modeling
year: 2014
month: 10
day: 13
published: true
summary: This is a hands-on walkthrough on how <B>PCA</B> can reduce a 1000+ variable data set into 10 variables and barely lose accuracy! This is incredible, and everytime I play around with this, I still get amazed! 
image: dimension-reduction/pca.png
---

**Resources**
<ul>
<li type="square">YouTube Companion Video: </li>
<li type="square"><a href="#sourcecode">Full source code</a>
</li>
</ul>
<BR>
**Packages Used in this Walkthrough**

<ul>
        <li type="square"><b>{prcomp}</b> - for pca</li>
        <li type="square"><b>{xgboost}</b> - modeling algorithm</li>
        <li type="square"><b>{Metrics}</b> - measuring accuracy/AUC</li>
        <li type="square"><b>{caret}</b> - reducing zero/near-zero variance</li>
</ul>
<BR>
**Introduction**

I can't remember the last time I worked on a data sets with less than **1000** features. Not a big deal with today's computing power, but it can become a unwieldy when you need to use certain forest-based models, heavy cross-validation, grid tuning, and any ensemble work. <i>Note: the term variables, features, predictors are used throughout and mean the same thing.</i>

Off the bat, there are 3 ways of dealing with **high-dimensionality data** (i.e. having too many variables):

<ol>
<li>get more computing muscle (like RStudio on an <a href='http://amunategui.github.io/EC2-RStudioServer/' target='_blank'>Amazon web server EC2</a> instance),</li>
<li>prune your data set using <a href='http://en.wikipedia.org/wiki/Feature_selection' target='_blank'>feature selection</a> (measure variables effectiveness and keep only the best - built-in feature selection - <a href='http://amunategui.github.io/fscaret-Walkthrough/' target='_blank'>see fscaret</a>),</li>
<li>and finally, the subject of this walkthrough, use <B>feature reduciton</B> (also refereed as <a href="http://en.wikipedia.org/wiki/Dimensionality_reduction">feature extraction</a>) to create new variables made of bits and pieces of the original variables.</li>
</ol>

According to <a href='http://en.wikipedia.org/wiki/Dimensionality_reduction' target='_blank'>wikipedia</a>:

<ul>"Principal component analysis (PCA) is a statistical procedure that uses an orthogonal transformation to convert a set of observations of possibly correlated variables into a set of values of linearly uncorrelated variables called principal components."</ul>

There's mountains of details on the web on this topic, but, in a nutshell, it looks for the set of variables in your data that explains most of your variance and creates a new feature out of it. This becomes your first component. It will then keep doing so on the next set of variables unrelated to the first one, and that will become your next component. And so on and so forth. This is done in an unsupervised manner so it doesn't care what your repsonse variable/outcome is. This is the basis of a lot of compression software - and it works really well.

**Lets code!**

To get us started, we need a very large data set. We don't need many rows, but we want as many columns as possible! We're going to borrow a data set from <a href='http://www.nipsfsc.ecs.soton.ac.uk/' target='_blank'>NIPS (Neural Information Processing Systems)</a> from a 2013 competition that they still make avaialble for us to learn from. WE download the <a href='http://www.nipsfsc.ecs.soton.ac.uk/datasets/' target='_blank'>GISETTE</a> data set (**warning:** this is a large file):


```r
temp <- tempfile()
download.file("http://www.nipsfsc.ecs.soton.ac.uk/datasets/GISETTE.zip",temp, mode="wb")
unzip(temp, "GISETTE/gisette_train.data")
gisetteRaw <- read.table("GISETTE/gisette_train.data", sep=" ",skip=0, header=F)
unzip(temp, "GISETTE/gisette_train.labels")
g_labels <- read.table("GISETTE/gisette_train.labels", sep=" ",skip=0, header=F)

print(dim(gisetteRaw))
```

```
## [1] 6000 5001
```

``gisetteRaw`` is a large file with many columns and we need to remove redundant columns that will slow down (or crash the pca process). The ``nearZeroVar`` function with the ``saveMetrics`` parameter set to **true** will return the degree of feature variance:

```r
nzv <- nearZeroVar(gisetteRaw, saveMetrics = TRUE)
print(paste('Range:',range(nzv$percentUnique)))
```

```
## [1] "Range: 0"   "Range: 8.6"
```

```r
print(head(nzv))
```

```
##    freqRatio percentUnique zeroVar  nzv
## V1     48.25        5.2167   FALSE TRUE
## V2   1180.80        1.3667   FALSE TRUE
## V3     41.32        6.1500   FALSE TRUE
## V4   5991.00        0.1667   FALSE TRUE
## V5    980.00        1.5333   FALSE TRUE
## V6    140.00        3.5167   FALSE TRUE
```
We remove features with less than 0.1% variance:

```r
print(paste('Column count before cutoff:',ncol(gisetteRaw)))
```

```
## [1] "Column count before cutoff: 5001"
```

```r
dim(nzv[nzv$percentUnique > 0.1,])
```

```
## [1] 4639    4
```

```r
gisette_nzv <- gisetteRaw[c(rownames(nzv[nzv$percentUnique > 0.1,])) ]
print(paste('Column count after cutoff:',ncol(gisette_nzv)))
```

```
## [1] "Column count before cutoff: 4639"
```
Now that we have a data cleaned up and ready to go, let's see how well it performs. We add the labels (response or outcome variables) to the set:

```r
dfEvaluate <- cbind(as.data.frame(sapply(gisette_nzv, as.numeric)),
              cluster=g_labels$V1)
```
We're going to feed it to a cross-validation loop in order to run the data 5 times, each time assigning a new chunk as training and testing. This allows to get a stable AUC (Area Under the Curve) score.


```r
CVs <- 5
cvDivider <- floor(nrow(dfEvaluate) / (CVs+1))
indexCount <- 1
outcomeName <- c('cluster')
predictors <- names(dfEvaluate)[!names(dfEvaluate) %in% outcomeName]
lsErr <- c()
lsAUC <- c()
for (cv in seq(1:CVs)) {
        print(paste('cv',cv))
        dataTestIndex <- c((cv * cvDivider):(cv * cvDivider + cvDivider))
        dataTest <- dfEvaluate[dataTestIndex,]
        dataTrain <- dfEvaluate[-dataTestIndex,]
        
        bst <- xgboost(data = as.matrix(dataTrain[,predictors]),
                       label = dataTrain[,outcomeName],
                       max.depth=6, eta = 1, verbose=0,
                       nround=5, nthread=4, 
                       objective = "reg:linear")
        
        predictions <- predict(bst, as.matrix(dataTest[,predictors]), outputmargin=TRUE)
        err <- rmse(dataTest[,outcomeName], predictions)
        auc <- auc(dataTest[,outcomeName],predictions)
        
        lsErr <- c(lsErr, err)
        lsAUC <- c(lsAUC, auc)
        gc()
}
```

```
## [1] "cv 1"
## [1] "cv 2"
## [1] "cv 3"
## [1] "cv 4"
## [1] "cv 5"
```

```r
print(mean(lsAUC))
```

```
## [1] 0.9659
```
This yields a great AUC score (remember, AUC of 0.5 is random, and 1.0 is perfect). But we don't really care how well the model did, we just want to use that AUC score as basis to compare the same model but with data transformed through PCA.

So, lets use the same data and run it through ``prcomp``. This will transform all the variables by importance of variation - meaning that the first component variable will contain most of the variation from the data and therefore be the most powerful one (**Warning:** this can be a very slow to process depending on your machine - so do it once and store the resulting data set for later use):

```r
pmatrix <- scale(gisette_nzv)
princ <- prcomp(pmatrix)
```

Let's start by running the same cross-validation code with just the **first PCA component** (remember, this holds most of the variation of the data):

```r
nComp <- 1  
dfComponents <- predict(princ, newdata=pmatrix)[,1:nComp]

dfEvaluate <- cbind(as.data.frame(dfComponents),
              cluster=g_labels$V1)

cvDivider <- floor(nrow(dfEvaluate) / (CVs+1))
indexCount <- 1
predictors <- names(dfEvaluate)[!names(dfEvaluate) %in% outcomeName]
lsErr <- c()
lsAUC <- c()
for (cv in seq(1:CVs)) {
        print(paste('cv',cv))
        dataTestIndex <- c((cv * cvDivider):(cv * cvDivider + cvDivider))
        dataTest <- dfEvaluate[dataTestIndex,]
        dataTrain <- dfEvaluate[-dataTestIndex,]
        
        bst <- xgboost(data = as.matrix(dataTrain[,predictors]),
                       label = dataTrain[,outcomeName],
                       max.depth=6, eta = 1, verbose=0,
                       nround=5, nthread=4, 
                       objective = "reg:linear")
        
        predictions <- predict(bst, as.matrix(dataTest[,predictors]), outputmargin=TRUE)
        err <- rmse(dataTest[,outcomeName], predictions)
        auc <- auc(dataTest[,outcomeName],predictions)
        
        lsErr <- c(lsErr, err)
        lsAUC <- c(lsAUC, auc)
        gc()
}
```

```
## [1] "cv 1"
## [1] "cv 2"
## [1] "cv 3"
## [1] "cv 4"
## [1] "cv 5"
```

```r
print(mean(lsAUC))
```

```
## [1] 0.719
```

The result isn't that good compared to the orginal, non-transformed data set. Let's try this again with 2 components:

```r
nComp <- 2  
...
print(mean(lsAUC))
```

```
## [1] 0.7228
```
Two components still don't give us a great score, let's jump to **5** components:

```r
nComp <- 5
...
print(mean(lsAUC))
```

```
## [1] 0.9279
```
Now we're talking! Let's try **10** compoenents:

```r
nComp <- 10
...
print(mean(lsAUC))
```

```
## [1] 0.9651
```

Now we're talking! Let's try **20** compoenents:

```r
nComp <- 20
...
print(mean(lsAUC))
```

```
## [1] 0.9641
```

**Additional Things**
Though out of scope for this hands-on post, checkout clusterboot


<BR><BR>        
<a id="sourcecode">Full source code (<a href='https://github.com/amunategui/pca-dimension-reduction' target='_blank'>also on GitHub</a>)</a>:

```r

require(xgboost)
require(Metrics)
require(ROCR)
require(caret)
require(ggplot2)

EvaluateAUC <- function(dfEvaluate) {
        CVs <- 5
        cvDivider <- floor(nrow(dfEvaluate) / (CVs+1))
        indexCount <- 1
        outcomeName <- c('cluster')
        predictors <- names(dfEvaluate)[!names(dfEvaluate) %in% outcomeName]
        lsErr <- c()
        lsAUC <- c()
        for (cv in seq(1:CVs)) {
                print(paste('cv',cv))
                dataTestIndex <- c((cv * cvDivider):(cv * cvDivider + cvDivider))
                dataTest <- dfEvaluate[dataTestIndex,]
                dataTrain <- dfEvaluate[-dataTestIndex,]
                
                bst <- xgboost(data = as.matrix(dataTrain[,predictors]),
                               label = dataTrain[,outcomeName],
                               max.depth=6, eta = 1, verbose=0,
                               nround=5, nthread=4, 
                               objective = "reg:linear")
                
                predictions <- predict(bst, as.matrix(dataTest[,predictors]), outputmargin=TRUE)
                err <- rmse(dataTest[,outcomeName], predictions)
                auc <- auc(dataTest[,outcomeName],predictions)
                
                lsErr <- c(lsErr, err)
                lsAUC <- c(lsAUC, auc)
                gc()
        }
        print(paste('Mean Error:',mean(lsErr)))
        print(paste('Mean AUC:',mean(lsAUC)))
}

##########################################################################################
## Download data
##########################################################################################

# http://www.nipsfsc.ecs.soton.ac.uk/datasets/GISETTE.zip
# http://stat.ethz.ch/R-manual/R-devel/library/stats/html/princomp.html
temp <- tempfile()

# word of warning, this is 20mb - slow
download.file("http://www.nipsfsc.ecs.soton.ac.uk/datasets/GISETTE.zip",temp, mode="wb")
dir(tempdir())

unzip(temp, "GISETTE/gisette_train.data")
gisetteRaw <- read.table("GISETTE/gisette_train.data", sep=" ",skip=0, header=F)
unzip(temp, "GISETTE/gisette_train.labels")
g_labels <- read.table("GISETTE/gisette_train.labels", sep=" ",skip=0, header=F)

##########################################################################################
## Remove zero and close to zero variance
##########################################################################################

nzv <- nearZeroVar(gisetteRaw, saveMetrics = TRUE)
range(nzv$percentUnique)

# how many have no variation at all
print(length(nzv[nzv$zeroVar==T,]))

print(paste('Column count before cutoff:',ncol(gisetteRaw)))

# how many have less than 0.1 percent variance
dim(nzv[nzv$percentUnique > 0.1,])

# remove zero & near-zero variance from original data set
gisette_nzv <- gisetteRaw[c(rownames(nzv[nzv$percentUnique > 0.1,])) ]
print(paste('Column count after cutoff:',ncol(gisette_nzv)))

##########################################################################################
# Run model on original data set
##########################################################################################

dfEvaluate <- cbind(as.data.frame(sapply(gisette_nzv, as.numeric)),
                    cluster=g_labels$V1)

EvaluateAUC(dfEvaluate)

##########################################################################################
# Run prcomp on the data set
##########################################################################################

pmatrix <- scale(gisette_nzv)
princ <- prcomp(pmatrix)

# plot the first two components
ggplot(dfEvaluate, aes(x=PC1, y=PC2, colour=as.factor(g_labels$V1+1))) +
        geom_point(aes(shape=as.factor(g_labels$V1))) + scale_colour_hue()

# full - 0.965910574495451
nComp <- 5  
nComp <- 10  
nComp <- 90     
nComp <- 20  
nComp <- 50   
nComp <- 100   

# change nComp to try different numbers of component variables (10 works great)
nComp <- 10  # 0.9650
dfComponents <- predict(princ, newdata=pmatrix)[,1:nComp]
dfEvaluate <- cbind(as.data.frame(dfComponents),
                    cluster=g_labels$V1)

EvaluateAUC(dfEvaluate)
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
 
 