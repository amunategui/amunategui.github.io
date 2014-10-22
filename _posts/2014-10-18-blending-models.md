---
layout: post
title: Modeling Ensembles with <b>R</b> and <b>{Caret}</b>
category: Machine Learning
tags: modeling
year: 2014
month: 10
day: 18
published: true
summary: If you can model, then you can model ensembles! It’s literally as simple as running multiple <b>R</b> models on the same data, collecting the predictions, and blending them using a final model. And, if all goes well, you should enjoy a bump in <b>AUC</b> score!
image: blending-models/blending.png
---

**Resources**
<ul>
<li type="square"><a href="https://www.youtube.com/watch?v=k7sTiTWWCXM" target='_blank'>YouTube Companion Video</a></li>
<li type="square"><a href="#sourcecode">Full Source Code</a></li>
</ul>
<BR>
**Packages Used in this Walkthrough**

<ul>
        <li type="square"><b>{caret}</b> - modeling wrapper, functions, commands</li>
        <li type="square"><b>{RCurl}</b> - web data downloading functions</li>
        <li type="square"><b>{pROC}</b> - Area Under the Curve (AUC) functions</li>
</ul>
<BR><BR>

There are many reasons to ensemble models but it usually comes down to capturing a deeper understanding of high dimensionality data. The more complex a data set, the more it benefits from additional models, just like additional eyes, to capture more nuances scattered around high dimensionality data.
<br><br>
**Let’s code!**

This walkthrough leverages the **caret** package for ease of coding but the concept applies to any model in any statistical programming language. **Caret** allows you to easily switch models in a script without having to change much of the code. You can easily write a loop and have it run through the almost 170 models that the package currently supports (<a href='http://cran.r-project.org/web/packages/caret/vignettes/caret.pdf' target='_blank'>Max Kuhn keeps adding new ones</a>) by only changing one variable. 

To get a complete list of the models supported by **caret** use the ``getModelInfo`` function:

```r
library(caret)
names(getModelInfo())
```

```
##   [1] "ada"                 "ANFIS"               "avNNet"             
##   [4] "bag"                 "bagEarth"            "bagFDA"             
##   [7] "bayesglm"            "bdk"                 "blackboost"         
##  [10] "Boruta"              "brnn"                "bstLs"              
##  [13] "bstSm"               "bstTree"             "C5.0"               
##  [16] "C5.0Cost"            "C5.0Rules"           "C5.0Tree"           
##  [19] "cforest"             "CSimca"              "ctree"              
##  [22] "ctree2"              "cubist"              "DENFIS"             
##  [25] "dnn"                 "earth"               "elm"                
##  [28] "enet"                "evtree"              "extraTrees"         
##  [31] "fda"                 "FH.GBML"             "FIR.DM"             
##  [34] "foba"                "FRBCS.CHI"           "FRBCS.W"            
##  [37] "FS.HGD"              "gam"                 "gamboost"           
##  [40] "gamLoess"            "gamSpline"           "gaussprLinear"      
##  [43] "gaussprPoly"         "gaussprRadial"       "gbm"                
##  [46] "gcvEarth"            "GFS.FR.MOGAL"        "GFS.GCCL"           
##  [49] "GFS.LT.RS"           "GFS.Thrift"          "glm"                
##  [52] "glmboost"            "glmnet"              "glmStepAIC"         
##  [55] "gpls"                "hda"                 "hdda"               
##  [58] "HYFIS"               "icr"                 "J48"                
##  [61] "JRip"                "kernelpls"           "kknn"               
##  [64] "knn"                 "krlsPoly"            "krlsRadial"         
##  [67] "lars"                "lars2"               "lasso"              
##  [70] "lda"                 "lda2"                "leapBackward"       
##  [73] "leapForward"         "leapSeq"             "Linda"              
##  [76] "lm"                  "lmStepAIC"           "LMT"                
##  [79] "logicBag"            "LogitBoost"          "logreg"             
##  [82] "lssvmLinear"         "lssvmPoly"           "lssvmRadial"        
##  [85] "lvq"                 "M5"                  "M5Rules"            
##  [88] "mda"                 "Mlda"                "mlp"                
##  [91] "mlpWeightDecay"      "multinom"            "nb"                 
##  [94] "neuralnet"           "nnet"                "nodeHarvest"        
##  [97] "oblique.tree"        "OneR"                "ORFlog"             
## [100] "ORFpls"              "ORFridge"            "ORFsvm"             
## [103] "pam"                 "parRF"               "PART"               
## [106] "partDSA"             "pcaNNet"             "pcr"                
## [109] "pda"                 "pda2"                "penalized"          
## [112] "PenalizedLDA"        "plr"                 "pls"                
## [115] "plsRglm"             "ppr"                 "protoclass"         
## [118] "qda"                 "QdaCov"              "qrf"                
## [121] "qrnn"                "rbf"                 "rbfDDA"             
## [124] "rda"                 "relaxo"              "rf"                 
## [127] "rFerns"              "RFlda"               "ridge"              
## [130] "rknn"                "rknnBel"             "rlm"                
## [133] "rocc"                "rpart"               "rpart2"             
## [136] "rpartCost"           "RRF"                 "RRFglobal"          
## [139] "rrlda"               "RSimca"              "rvmLinear"          
## [142] "rvmPoly"             "rvmRadial"           "SBC"                
## [145] "sda"                 "sddaLDA"             "sddaQDA"            
## [148] "simpls"              "SLAVE"               "slda"               
## [151] "smda"                "sparseLDA"           "spls"               
## [154] "stepLDA"             "stepQDA"             "superpc"            
## [157] "svmBoundrangeString" "svmExpoString"       "svmLinear"          
## [160] "svmPoly"             "svmRadial"           "svmRadialCost"      
## [163] "svmRadialWeights"    "svmSpectrumString"   "treebag"            
## [166] "vbmpRadial"          "widekernelpls"       "WM"                 
## [169] "xyf"
```
<BR><BR>
As you can see, there are plenty of models available to satisfy most needs. Some support either **dual use**, while others are either **classification** or **regression** only. You can test for the type a model supports using the same ``getModelInfo`` function:

```r
getModelInfo()$glm$type
```
```
#  "Regression"     "Classification"
```

In the above snippet, ``glm`` supports both **regression** and **classification**.
<BR><BR>
We download the **vehicles** data set from <a href='https://github.com/hadley' target='_blank'>Hadley Wickham</a> hosted on Github. To keep this simple, we attempt to predict whether a vehicle has 6 cylinders using only the first 24 columns of the data set:

```r
library(RCurl)
urlfile <-'https://raw.githubusercontent.com/hadley/fueleconomy/master/data-raw/vehicles.csv'
x <- getURL(urlfile, ssl.verifypeer = FALSE)
vehicles <- read.csv(textConnection(x))

# alternative way of getting the data if the above snippet doesn't work:
# urlData <- getURL('https://raw.githubusercontent.com/hadley/fueleconomy/master/data-raw/vehicles.csv')
# vehicles <- read.csv(text = urlData)
```
<BR><BR>
We clean the outcome variable ``cyclinders`` by assigning it ``1`` for 6 cyclinders and ``0`` for everything else:

```r
vehicles <- vehicles[names(vehicles)[1:24]]
vehicles <- data.frame(lapply(vehicles, as.character), stringsAsFactors=FALSE)
vehicles <- data.frame(lapply(vehicles, as.numeric))
vehicles[is.na(vehicles)] <- 0
vehicles$cylinders <- ifelse(vehicles$cylinders == 6, 1,0)
```
<BR><BR>
We call ``prop.table`` to understand the proportions of our outcome variable:

```r
prop.table(table(vehicles$cylinders))
```

```
##      0      1 
## 0.6506 0.3494
```
This tells us that 35% of the data represents a vehicle with 6 cylinders. So our data isn't perfectly balanced but it certainly isn't skewed or considered a rare event.

Here is the one complicated part, instead of splitting the data into 2 parts of ``train`` and ``test``, we split the data into 3 parts: ``ensembleData``, ``blenderData``, and ``testingData``:

```r
set.seed(1234)
vehicles <- vehicles[sample(nrow(vehicles)),]
split <- floor(nrow(vehicles)/3)
ensembleData <- vehicles[0:split,]
blenderData <- vehicles[(split+1):(split*2),]
testingData <- vehicles[(split*2+1):nrow(vehicles),]
```
<BR><BR>
We assign the outcome name to ``labelName`` and the predictor variables to ``predictors``:

```r
labelName <- 'cylinders'
predictors <- names(ensembleData)[names(ensembleData) != labelName]
```
<BR><BR>
We create a **caret** ``trainControl`` object to control the number of cross-validations performed (the more the better but for breivity we only require 3):

```r
myControl <- trainControl(method='cv', number=3, returnResamp='none')
```
<BR><BR>
**Benchmark Model**

We run the data on a ``gbm`` model without any enembling to use as a comparative benchmark:

```r
test_model <- train(blenderData[,predictors], blenderData[,labelName], method='gbm', trControl=myControl)
```
```
## Iter   TrainDeviance   ValidDeviance   StepSize   Improve
##      1        0.2147             nan     0.1000    0.0128
##      2        0.2044             nan     0.1000    0.0104
##      3        0.1962             nan     0.1000    0.0084
...
```
You'll see a series of the lines (as shown above) as it trains the``gbm`` model. 
<BR><BR>
We then use the model to predict 6-cylinder vehicles using the ``testingData`` data set and **pROC**'s ``auc`` function to get the <a href='https://www.kaggle.com/wiki/AreaUnderCurve' target='_blank'>Area Under the Curve (AUC)</a>:

```r
preds <- predict(object=test_model, testingData[,predictors])
library(pROC)
auc <- roc(testingData[,labelName], preds)
print(auc$auc) 
```
```
## Area under the curve: 0.99
```
It gives a fairly strong **AUC** score of 0.99 (remember that 0.5 is random and 1 is perfect). Hard to believe we can improve this score using an ensemble of models...
<BR><BR>
**Ensembles**

But we're going to try. We now use 3 models - ``gbm``, ``rpart``, and ``treebag`` as part of our **ensembles** of models and ``train`` them with the ``ensembleData`` data set:

```r
model_gbm <- train(ensembleData[,predictors], ensembleData[,labelName], method='gbm', trControl=myControl)

model_rpart <- train(ensembleData[,predictors], ensembleData[,labelName], method='rpart', trControl=myControl)

model_treebag <- train(ensembleData[,predictors], ensembleData[,labelName], method='treebag', trControl=myControl)
```
<BR><BR>
After our 3 models are trained, we use them to predict **6 cylinder vehicles** on the other two data sets: ``blenderData`` and ``testingData`` - **yes, both!!** We need to do this to harvest the predictions from both data sets as we're going to add those predictions as new features to the same data sets. So, as we have 3 models, we're going to add three new columns to both ``blenderData`` and ``testingData``:

```r
blenderData$gbm_PROB <- predict(object=model_gbm, blenderData[,predictors])
blenderData$rf_PROB <- predict(object=model_rpart, blenderData[,predictors])
blenderData$treebag_PROB <- predict(object=model_treebag, blenderData[,predictors])

testingData$gbm_PROB <- predict(object=model_gbm, testingData[,predictors])
testingData$rf_PROB <- predict(object=model_rpart, testingData[,predictors])
testingData$treebag_PROB <- predict(object=model_treebag, testingData[,predictors])
```
Please note how easy it is to add those values back to the original data set (follow where we assign the resulting predictions above).
<BR><BR>
Now we train a final **blending** model on the old data and the new predictions (we use ``gbm`` but that is completely arbitrary):

```r
predictors <- names(blenderData)[names(blenderData) != labelName]
final_blender_model <- train(blenderData[,predictors], blenderData[,labelName], method='gbm', trControl=myControl)
```
<BR><BR>
And we call ``predict`` and ``roc``/``auc`` functions to see how our blended ensemble model fared:

```r
preds <- predict(object=final_blender_model, testingData[,predictors])
auc <- roc(testingData[,labelName], preds)
print(auc$auc)
```

```
## Area under the curve: 0.993
```
<BR>
There you have it, an **AUC** bump of 0.003. This may not seem like much (and there are many ways of improving that score) but it should easily give you that extra edge on your next data science competition!!


<BR><BR>  
<a id="sourcecode">Full source code (<a href='https://github.com/amunategui/SimpleEnsembleBlending' target='_blank'>also on GitHub</a>)</a>:

```r

require(ROCR)
require(caret)
require(ggplot2)

EvaluateAUC <- function(dfEvaluate) {
        require(xgboost)
        require(Metrics)
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
 
 