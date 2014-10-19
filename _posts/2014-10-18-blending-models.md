---
layout: post
title: Modeling Ensembles with R and the {Caret}
category: Machine Learning
tags: exploring modeling
year: 2014
month: 10
day: 18
published: true
summary: If you can model, then you can model ensembles! It’s literally as simple as running multiple models on the same data, collecting the predictions, and blending them using a final model. And, if all goes well, you should enjoy an AUC lift!
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

There are many reasons to ensemble models but it usually comes down to capturing a deeper understanding of high dimensionality data. The more complex a data set, the more it benefits from additional models, just like additional eyes, in order to capture more nuances scattered around high dimensionality data.

**Let’s code!**

This walkthrough leverages the **caret** package for ease of coding but the concept will apply to any model in any statistical programming language. Caret allows you to easily switch models in a script without having to change much of the code. You can easily write a loop and have it run through the almost 170 models that the package currently supports (<a href='http://cran.r-project.org/web/packages/caret/vignettes/caret.pdf' target='_blank'>Max Kuhn keeps adding new ones</a>) by only having to change one variable. 

To get a complete list of the models supported by **caret**:

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
As you can see, there should be plenty to satisfy most needs. Most models support either **dual use**, **classification** or **regression** only. For a more comprehensive code base you can test for the type a particular model supports:

```r
getModelInfo()$glm$type
#  "Regression"     "Classification"
```
<BR><BR>
Here, ``glm`` supports both **regression** and **classification**.

We download the **vehicles** data set from <a href='https://github.com/hadley' target='_blank'>Hadley Wickham</a> from Github. To keep this simple, we only attempt to predict whether a vehicle has 6 cylinders using the first 24 columns of the data set:

```r

library(RCurl)
urlfile <-'https://raw.githubusercontent.com/hadley/fueleconomy/master/data-raw/vehicles.csv'
x <- getURL(urlfile, ssl.verifypeer = FALSE)
vehicles <- read.csv(textConnection(x))

# alternative way of getting the data
#urlData <- getURL('https://raw.githubusercontent.com/hadley/fueleconomy/master/data-raw/vehicles.csv')
#vehicles <- read.csv(text = urlData)
```
<BR><BR>
We clean the outcome variable ‘cyclinders’ as 1 for 6 cyclinders and 0 for everything else:

```r
vehicles <- vehicles[names(vehicles)[1:24]]
vehicles <- data.frame(lapply(vehicles, as.character), stringsAsFactors=FALSE)
vehicles <- data.frame(lapply(vehicles, as.numeric))
vehicles[is.na(vehicles)] <- 0
vehicles$cylinders <- ifelse(vehicles$cylinders == 6, 1,0)
```
<BR><BR>
We call ``prop.table`` to understand the proporting of our outcome variable:

```r
prop.table(table(vehicles$cylinders))
```

```
## 
##      0      1 
## 0.6506 0.3494
```
This tells us that 35% of the data represents a vehicle with 6 cylinders.

Here is the one complicated part, instead of the usual 2 part split of ``train`` and ``test`` data sets, we split our data into 3 parts: ``ensembleData``, ``blenderData``, and ``testingData``.

```r
# shuffle and split the data into three parts
set.seed(1234)
vehicles <- vehicles[sample(nrow(vehicles)),]
split <- floor(nrow(vehicles)/3)
ensembleData <- vehicles[0:split,]
blenderData <- vehicles[(split+1):(split*2),]
testingData <- vehicles[(split*2+1):nrow(vehicles),]

# set label name and predictors
labelName <- 'cylinders'
predictors <- names(ensembleData)[names(ensembleData) != labelName]

# create a caret control object to control the number of cross-validations performed
myControl <- trainControl(method='cv', number=3, returnResamp='none')

# quick benchmark model 
test_model <- train(blenderData[,predictors], blenderData[,labelName], method='gbm', trControl=myControl)
```

```
## Iter   TrainDeviance   ValidDeviance   StepSize   Improve
##      1        0.2147             nan     0.1000    0.0128
##      2        0.2044             nan     0.1000    0.0104
##      3        0.1962             nan     0.1000    0.0084
...
```

```r
preds <- predict(object=test_model, testingData[,predictors])

library(pROC)
```

```
## Type 'citation("pROC")' for a citation.
## 
## Attaching package: 'pROC'
## 
## The following objects are masked from 'package:stats':
## 
##     cov, smooth, var
```

```r
auc <- roc(testingData[,labelName], preds)
print(auc$auc) # Area under the curve: 0.9896
```

```
## Area under the curve: 0.99
```

```r
# train all the ensemble models with ensembleData
model_gbm <- train(ensembleData[,predictors], ensembleData[,labelName], method='gbm', trControl=myControl)
```


```
## Iter   TrainDeviance   ValidDeviance   StepSize   Improve
##      1        0.2130             nan     0.1000    0.0127
##      2        0.2026             nan     0.1000    0.0103
##      3        0.1943             nan     0.1000    0.0084
```

```r
model_rpart <- train(ensembleData[,predictors], ensembleData[,labelName], method='rpart', trControl=myControl)
```

```
## Loading required package: rpart
```

```
## Warning: There were missing values in resampled performance measures.
```

```r
model_treebag <- train(ensembleData[,predictors], ensembleData[,labelName], method='treebag', trControl=myControl)
```

```
## Loading required package: ipred
```

```r
# get predictions for each ensemble model for two last data sets
# and add them back to themselves
blenderData$gbm_PROB <- predict(object=model_gbm, blenderData[,predictors])
blenderData$rf_PROB <- predict(object=model_rpart, blenderData[,predictors])
blenderData$treebag_PROB <- predict(object=model_treebag, blenderData[,predictors])
testingData$gbm_PROB <- predict(object=model_gbm, testingData[,predictors])
testingData$rf_PROB <- predict(object=model_rpart, testingData[,predictors])
testingData$treebag_PROB <- predict(object=model_treebag, testingData[,predictors])

# see how each individual model performed on its own
auc <- roc(testingData[,labelName], testingData$gbm_PROB )
print(auc$auc) # Area under the curve: 0.9893
```

```
## Area under the curve: 0.989
```

```r
auc <- roc(testingData[,labelName], testingData$rf_PROB )
print(auc$auc) # Area under the curve: 0.958
```

```
## Area under the curve: 0.958
```

```r
auc <- roc(testingData[,labelName], testingData$treebag_PROB )
print(auc$auc) # Area under the curve: 0.9734
```

```
## Area under the curve: 0.973
```

```r
# run a final model to blend all the probabilities together
predictors <- names(blenderData)[names(blenderData) != labelName]
final_blender_model <- train(blenderData[,predictors], blenderData[,labelName], method='gbm', trControl=myControl)
```

```
## Warning: variable 3: charge120 has no variation.
```

```
## Iter   TrainDeviance   ValidDeviance   StepSize   Improve
##      1        0.1922             nan     0.1000    0.0355
##      2        0.1634             nan     0.1000    0.0288
##      3        0.1393             nan     0.1000    0.0233
...
```

```r
# See final prediction and AUC of blended ensemble
preds <- predict(object=final_blender_model, testingData[,predictors])
auc <- roc(testingData[,labelName], preds)
print(auc$auc)  # Area under the curve: 0.9922
```

```
## Area under the curve: 0.993
```

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
 
 