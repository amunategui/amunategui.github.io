---
layout: post
title: "Bagging  / Bootstrap Aggregation with R" 
category: Machine Learning
tags: modeling
year: 2015
month: 03
day: 07
published: true
summary: "Bagging is the not-so-secret edge of the competitive modeler. By sampling and modeling a training data set hundreds of times and averaging its predictions, you may just get that accuracy boost that puts your above the fray."
image: bagging-in-R/PotOfGold.png
---
<BR>
**Resources**
<ul>
<li type="square"><a href="https://www.youtube.com/user/mamunate/videos" target='_blank'>YouTube Companion Video</a></li>
<li type="square"><a href="#sourcecode">Full Source Code</a></li>
</ul>
<BR>
**Packages/Functions Used in this Walkthrough**

<ul>
        <li type="square"><a href='http://cran.r-project.org/web/packages/RCurl/index.html' targer='_blank'>{RCurl}</a> - General network (HTTP/FTP/...) client interface for R</li>
        <li type="square"><a href='http://cran.r-project.org/web/packages/pROC/index.html' targer='_blank'>{pROC}</a> - Display and analyze ROC curves</li>
        <li type="square"><a href='http://www.inside-r.org/r-doc/stats/lm' targer='_blank'>{stats} lm</a> - Fitting Linear Models</li>
        <li type="square"><a href='http://cran.r-project.org/web/packages/foreach/index.html' targer='_blank'>{foreach}</a> - Foreach looping construct for R</li>
        <li type="square"><a href='http://cran.r-project.org/web/packages/doParallel/index.html' targer='_blank'>{doParallel}</a> - Foreach parallel adaptor for the parallel package</li>
       
</ul>

<BR><BR>
In simple terms, bagging irons out variance from a data set. If, after splitting your data into multiple chunks and training them, you find that your predictions are different, your data has variance. Bagging can turn a bad thing into a competitive advantage. For more theory behind the magic, check out <a href='http://en.wikipedia.org/wiki/Bootstrap_aggregating' targer='_blank'>Bootstrap Aggregating</a> on Wikipedia.

<BR><BR>
**Stability and Accuracy**

By saving each prediction set and averaging them together, you not only <a href='http://en.wikipedia.org/wiki/Bias%E2%80%93variance_tradeoff' targer='_blank'>lower variance without affecting bias</a>, but your accuracy may be improved! In essence, you are creating many slightly different models and ensembling them together; this avoids over-fitting, stabilizes your predictions and increases your accuracy. Mind you, this assumes your data has variance, if it doesn't, bagging won't help.

<BR><BR>
**Let’s Code!**

We'll be using a great healthcare data set on historical readmissions of patients with diabetes - <a href='https://archive.ics.uci.edu/ml/machine-learning-databases/00296/' target='_blank'>Diabetes 130-US hospitals for years 1999-2008</a> Data Set. Readmissions is a big deal for hospitals in the US as Medicare/Medicaid will scrutinize those bills and, in some cases, only reimburse a percentage of them. We’ll use code to automate the download and unzipping of the data directly from the <a href='https://archive.ics.uci.edu/ml/index.html' target='_blank'>UC Irvine Machine Learning Repository</a>. 


```r
require(RCurl)
binData <- getBinaryURL("https://archive.ics.uci.edu/ml/machine-learning-databases/00296/dataset_diabetes.zip",
                    ssl.verifypeer=FALSE)

conObj <- file("dataset_diabetes.zip", open = "wb")
writeBin(binData, conObj)
# don't forget to close it
close(conObj)

# open diabetes file
files <- unzip("dataset_diabetes.zip")
diabetes <- read.csv(files[1], stringsAsFactors = FALSE)
```
<BR><BR>
Let's clean it up the data set and drop a few columns to keep things simple:


```r
# drop useless variables
diabetes <- subset(diabetes,select=-c(encounter_id, patient_nbr))

# transform all "?" to 0s
diabetes[diabetes == "?"] <- NA

# remove zero variance - ty James http://stackoverflow.com/questions/8805298/quickly-remove-zero-variance-variables-from-a-data-frame
diabetes <- diabetes[sapply(diabetes, function(x) length(levels(factor(x,exclude=NULL)))>1)]

# prep outcome variable to those readmitted under 30 days
diabetes$readmitted <- ifelse(diabetes$readmitted == "<30",1,0)

# generalize outcome name
outcomeName <- 'readmitted'

# drop large factors
diabetes <- subset(diabetes, select=-c(diag_1, diag_2, diag_3))
```
<BR><BR>
Let's binarize all factor, character, and un-ordered categorical numerical values. The code below will print out what needs to be transformed and how many unique columns need to be created. We aren't using <a href='http://amunategui.github.io/dummyVar-Walkthrough/' target='_blank'>full rank</a> here.

```r
# binarize data
charcolumns <- names(diabetes[sapply(diabetes, is.character)])
for (colname in charcolumns) {
     print(paste(colname,length(unique(diabetes[,colname]))))
     for (newcol in unique(diabetes[,colname])) {
          if (!is.na(newcol))
               diabetes[,paste0(colname,"_",newcol)] <- ifelse(diabetes[,colname]==newcol,1,0)
     }
     diabetes <- diabetes[,setdiff(names(diabetes),colname)]
}
```
```
## [1] "race 6"
## [1] "gender 3"
## [1] "age 10"
## [1] "weight 10"
## [1] "payer_code 18"
## [1] "medical_specialty 73"
## [1] "max_glu_serum 4"
## [1] "A1Cresult 4"
## [1] "metformin 4"
## [1] "repaglinide 4"
## [1] "nateglinide 4"
## [1] "chlorpropamide 4"
## [1] "glimepiride 4"
## [1] "acetohexamide 2"
## [1] "glipizide 4"
## [1] "glyburide 4"
## [1] "tolbutamide 2"
## [1] "pioglitazone 4"
## [1] "rosiglitazone 4"
## [1] "acarbose 4"
## [1] "miglitol 4"
## [1] "troglitazone 2"
## [1] "tolazamide 3"
## [1] "insulin 4"
## [1] "glyburide.metformin 4"
## [1] "glipizide.metformin 2"
## [1] "glimepiride.pioglitazone 2"
## [1] "metformin.rosiglitazone 2"
## [1] "metformin.pioglitazone 2"
## [1] "change 2"
## [1] "diabetesMed 2"
```

```r
# remove all punctuation characters in column names after binarization that could trip R
colnames(diabetes) <- gsub(x =colnames(diabetes), pattern="[[:punct:]]", replacement = "_" )
 
# check for zero variance
diabetes <- diabetes[sapply(diabetes, function(x) length(levels(factor(x,exclude=NULL)))>1)]

# transform all NAs into 0
diabetes[is.na(diabetes)] <- 0 
```
<BR><BR>
**A Simple Bag-Free Model for Comparison**

We're going to use the base function <a href='http://www.inside-r.org/r-doc/stats/lm' targer='_blank'>lm (linear models)</a> to model our training split:

```r
# split data set into training and testing
set.seed(1234)
split <- sample(nrow(diabetes), floor(0.5*nrow(diabetes)))
traindf <- diabetes[split,]
testdf <-  diabetes[-split,]

predictorNames <- setdiff(names(traindf), outcomeName)
fit <- lm(readmitted ~ ., data = traindf)
preds <- predict(fit, testdf[,predictorNames], se.fit = TRUE)

library(pROC)
print(auc(testdf[,outcomeName], preds$fit))
```
```
## Area under the curve: 0.6408224
```
<BR><BR>
The ``AUC`` score (Area Under the Curve) of our simple ``lm`` model is <b>0.6408224</b>. The score itself doesn't really matter as we're only interested in it as a comparative benchmark.

  
<BR><BR>
**Let's Bag It!**

Now we're going to bag this data using the same ``lm`` model. To make things go faster, we're going to parallelize the loop and spread the task to ``8`` processors; you'll need to tweak the ``makeCluster`` parameter for your hardware. The ``length_divisor`` parameter sets the size of how many rows to use in each sample, while ``m`` in the ``foreach`` loop sets how many times to run samples. Note that the ``sample`` function doesn't use a ``seed``, this is important as we want each new sample to be made from the full set of rows available, regardless if a row has already been used.

```r
# parallel   ---------------------------------------------------------
library(foreach)
library(doParallel)

#setup parallel back end to use 8 processors
cl<-makeCluster(8)
registerDoParallel(cl)

# divide row size by 20, sample data 400 times 
ength_divisor <- 20
predictions<-foreach(m=1:400,.combine=cbind) %dopar% { 
        # using sample function without seed
     sampleRows <- sample(nrow(traindf), size=floor((nrow(traindf)/length_divisor)))
     fit <- lm(readmitted ~ ., data = traindf[sampleRows,])
     predictions <- data.frame(predict(object=fit, testdf[,predictorNames], se.fit = TRUE)[[1]])
} 
stopCluster(cl)

library(pROC)
auc(testdf[,outcomeName], rowMeans(predictions))
```
```
## Area under the curve: 0.6422938
```
<BR><BR>
Our final ``AUC`` score of <b>0.6422938</b> is a small improvement over the simple model's ``AUC`` of 0.6408224. Even though this may not feel like a huge improvement, its that kind of little push that will place you above other players in data science competitions. This does require trial and error to find the right mix of sample size and number of runs. 

<BR><BR>
**Conclusion**

Bagging is very common in competitions. I don’t think I have ever seen anybody win without using it. But, in order for this to work, your data must have variance, otherwise you’re just adding levels after levels of additional iterations with little benefit to your score and a big headache for those maintaining your modeling pipeline in production. Even when it does improve things, you have to asked yourself if its worth all that extra work...

This walkthrough was inspired by Vik Paruchuri and his blog entry: <a href="http://www.vikparuchuri.com/blog/build-your-own-bagging-function-in-r/" target="_blank">Improve Predictive Performance in R with Bagging</a>.

<BR><BR>        
<a id="sourcecode">Full source code (<a href='https://github.com/amunategui/feature-hashing-walkthrough/blob/master/feature-hasher-walkthrough.r' target='_blank'>also on GitHub</a>)</a>:

```r
require(RCurl)
binData <- getBinaryURL("https://archive.ics.uci.edu/ml/machine-learning-databases/00296/dataset_diabetes.zip",
                    ssl.verifypeer=FALSE)

conObj <- file("dataset_diabetes.zip", open = "wb")
writeBin(binData, conObj)
# don't forget to close it
close(conObj)

# open diabetes file
files <- unzip("dataset_diabetes.zip")
diabetes <- read.csv(files[1], stringsAsFactors = FALSE)

# drop useless variables
diabetes <- subset(diabetes,select=-c(encounter_id, patient_nbr))

# transform all "?" to 0s
diabetes[diabetes == "?"] <- NA

# remove zero variance - ty James http://stackoverflow.com/questions/8805298/quickly-remove-zero-variance-variables-from-a-data-frame
diabetes <- diabetes[sapply(diabetes, function(x) length(levels(factor(x,exclude=NULL)))>1)]

# prep outcome variable to those readmitted under 30 days
diabetes$readmitted <- ifelse(diabetes$readmitted == "<30",1,0)

# generalize outcome name
outcomeName <- 'readmitted'

# drop large factors
diabetes <- subset(diabetes, select=-c(diag_1, diag_2, diag_3))

# binarize data
charcolumns <- names(diabetes[sapply(diabetes, is.character)])
for (colname in charcolumns) {
     print(paste(colname,length(unique(diabetes[,colname]))))
     for (newcol in unique(diabetes[,colname])) {
          if (!is.na(newcol))
               diabetes[,paste0(colname,"_",newcol)] <- ifelse(diabetes[,colname]==newcol,1,0)
     }
     diabetes <- diabetes[,setdiff(names(diabetes),colname)]
}

# remove all punctuation characters in column names after binarization that could trip R
colnames(diabetes) <- gsub(x =colnames(diabetes), pattern="[[:punct:]]", replacement = "_" )
 
# check for zero variance
diabetes <- diabetes[sapply(diabetes, function(x) length(levels(factor(x,exclude=NULL)))>1)]

# transform all NAs into 0
diabetes[is.na(diabetes)] <- 0 

# split data set into training and testing
set.seed(1234)
split <- sample(nrow(diabetes), floor(0.5*nrow(diabetes)))
traindf <- diabetes[split,]
testdf <-  diabetes[-split,]

predictorNames <- setdiff(names(traindf), outcomeName)
fit <- lm(readmitted ~ ., data = traindf)
preds <- predict(fit, testdf[,predictorNames], se.fit = TRUE)

library(pROC)
print(auc(testdf[,outcomeName], preds$fit))

# parallel   ---------------------------------------------------------
library(foreach)
library(doParallel)

#setup parallel back end to use 8 processors
cl<-makeCluster(8)
registerDoParallel(cl)

# divide row size by 20, sample data 400 times 
# code based on Vik Paruchuri's blog entry: http://www.vikparuchuri.com/blog/build-your-own-bagging-function-in-r/
length_divisor <- 20
predictions<-foreach(m=1:400,.combine=cbind) %dopar% { 
        # using sample function without seed
     sampleRows <- sample(nrow(traindf), size=floor((nrow(traindf)/length_divisor)))
     fit <- lm(readmitted ~ ., data = traindf[sampleRows,])
     predictions <- data.frame(predict(object=fit, testdf[,predictorNames], se.fit = TRUE)[[1]])
} 
stopCluster(cl)

library(pROC)
print(auc(testdf[,outcomeName], rowMeans(predictions)))

```


