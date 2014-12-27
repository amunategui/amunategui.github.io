---
layout: post
title: Predicting Multiple Discrete Values with Multinomials, Neural Networks and the {nnet} Package
category: Machine Learning
tags: modeling
year: 2014
month: 11
day: 1
published: true
summary: Using R and the <b>multinom</b> function from the <b>nnet</b> package, we can easily predict discrete values (factors) of more than 2 levels. We also use <b>Repeated Cross Validation</b> to get an accurate model score and to understand the importance of allowing the model to converge (reaching global minima).
image: multinom-neuralnetworks/converged.png
---
**Resources**
<ul>
<li type="square"><a href="https://www.youtube.com/watch?v=zTlbMHw9CeY&list=UUq4pm1i_VZqxKVVOz5qRBIA" target='_blank'>YouTube Companion Video</a></li>
<li type="square"><a href="#sourcecode">Full Source Code</a></li>
</ul>
<BR>
**Packages Used in this Walkthrough**

<ul>
        <li type="square"><b>{nnet}</b> - neural network multinomial modeling</li>
        <li type="square"><b>{RCurl}</b> - downloads https data</li>
        <li type="square"><b>{caret}</b> - dummyVars and postResample function</li>
</ul>

<BR><BR>

So, what is a <b>multionmial model</b>? 

From <a href='http://en.wikipedia.org/wiki/Multinomial_logistic_regression' target='_blank'>Wikipedia</a>:

<blockquote>Multinomial logistic regression is a simple extension of binary logistic regression that allows for more than two categories of the dependent or outcome variable.</blockquote>

And from the ``multinom`` <b>{nnet}</b> help file:


```r
library(nnet)
?multinom
```

<blockquote>Fits multinomial log-linear models via neural networks.</blockquote>
<BR>
In a nutshell, this allows you to predict a factor of multiple levels (more than two) in one shot with the power of neural networks. <b>Neural networks</b> are great at working through multiple combinations and also great with linear models, so it's an ideal combination.
<BR><BR>

If your data is linear in nature, then instead of using multiple models and doing ``A`` versus ``B``, ``B`` versus ``C``, and ``C`` versus ``A``, and finally going through the hassle of concatenating the resulting probabilities, you can let <b>nnet</b> do it all in one shot. And this becomes exponentialy more difficult as you predict more than 3 outcome levels!! 
<BR><BR>

The ``multinom`` function will do all that for you in one shot and allow you to observe the probabilities of each subset to interpret things (now that's really cool). 
<BR><BR>

**Let's code!**

We're going to use a <a href='http://had.co.nz/' target='_blank'>Hadley Wickham</a> data set to predict how many cylinders a vehicle has. We download the data from <a href='https://github.com/hadley' target='_blank'>Github</a>:

```r
library(RCurl)
urlfile <-'https://raw.githubusercontent.com/hadley/fueleconomy/master/data-raw/vehicles.csv'
x <- getURL(urlfile, ssl.verifypeer = FALSE)
vehicles <- read.csv(textConnection(x))
```
<BR><BR>
Only use the first 24 columns of the data for simplicities sake. Cast all variables to numerics and impute any NAs with ``0``. 

```r
vehicles <- vehicles[names(vehicles)[1:24]]
vehicles <- data.frame(lapply(vehicles, as.character), stringsAsFactors=FALSE)
vehicles <- data.frame(lapply(vehicles, as.numeric))
vehicles[is.na(vehicles)] <- 0
names(vehicles)
```

```
##  [1] "barrels08"       "barrelsA08"      "charge120"      
##  [4] "charge240"       "city08"          "city08U"        
##  [7] "cityA08"         "cityA08U"        "cityCD"         
## [10] "cityE"           "cityUF"          "co2"            
## [13] "co2A"            "co2TailpipeAGpm" "co2TailpipeGpm" 
## [16] "comb08"          "comb08U"         "combA08"        
## [19] "combA08U"        "combE"           "combinedCD"     
## [22] "combinedUF"      "cylinders"       "displ"
```
<BR><BR>
Use the ``cyclinder`` column as the model's outcome and cast it to a factor. Use the ``table`` function to see how many types of cylinders we are dealing with (BTW a ``0`` cylinder vehicle is an electric vehicle):

```r
vehicles$cylinders <- as.factor(vehicles$cylinders)
table(vehicles$cylinders)
```

```
## 
##     0     2     3     4     5     6     8    10    12    16 
##    66    51   182 13133   757 12101  7715   138   481     7
```
We see that the 4 and 6 cylinder vehicles are the most numerous.
<BR><BR>

Shuffle the data and split it into two equal data frames so we can have a training and a testing data set:

```r
set.seed(1234)
vehicles <- vehicles[sample(nrow(vehicles)),]
split <- floor(nrow(vehicles)/2)
vehiclesTrain <- vehicles[0:split,]
vehiclesTest <- vehicles[(split+1):nrow(vehicles),]
```

<BR><BR>
Let's put <b>nnet</b> to work and predict cyclinders. The ``maxiter`` variable defaults to 100 when omitted so let's start with a large number during the first round to make sure we find the lowest possible error level (i.e. global minimum - solution with the lowest error possible):


```r
library(nnet)
cylModel <- multinom(cylinders~., data=vehiclesTrain, maxit=500, trace=T)
```

```
## # weights:  250 (216 variable)
## initial  value 39869.260885 
## iter  10 value 18697.133750
...
## iter 420 value 5217.401201
## final  value 5217.398483 
## converged
```
When you see the word <b>converged</b> in the log output, you know the model went as far as it could.
<BR><BR>
Let's find the most influential variables by using <b>caret's</b> ``varImp`` function:

```r
library(caret)
mostImportantVariables <- varImp(cylModel)
mostImportantVariables$Variables <- row.names(mostImportantVariables)
mostImportantVariables <- mostImportantVariables[order(-mostImportantVariables$Overall),]
print(head(mostImportantVariables))
```
```
## Variables  Overall    
## charge240  625.5732   
## cityUF     596.4079      
## combinedUF 580.1112  
## displ      434.8038
## cityE      395.3533       
## combA08    322.2910     
```
<BR><BR>
Next we predict ``cylinders`` using the ``predict`` function on the testing data set. There are two ways to compute predictions, ``class`` or ``probs``:

```r
preds1 <- predict(cylModel, type="probs", newdata=vehiclesTest)
head(preds1)
```

```
##                0          2          3         4         5         6
## 30632  1.966e-53  2.770e-38  3.232e-40 3.024e-02 4.728e-02 0.9222608
## 26204  4.310e-33 8.316e-112  5.884e-21 9.297e-01 3.009e-02 0.0401936
## 27378  1.211e-92  7.384e-65  5.948e-75 7.352e-09 2.823e-05 0.2919979
## 12346  2.808e-48  9.065e-29  3.301e-37 4.767e-02 9.357e-02 0.8580807
## 13664  2.428e-27  4.287e-33  8.640e-21 9.643e-01 2.190e-02 0.0137845
## 3357  1.654e-146 2.447e-119 2.731e-111 3.014e-17 2.733e-10 0.0004251
##               8        10        12         16
## 30632 2.198e-04 4.059e-09 2.837e-09  2.457e-89
## 26204 1.523e-06 6.732e-13 3.522e-16  4.859e-95
## 27378 7.019e-01 3.665e-03 2.452e-03  9.845e-46
## 12346 6.820e-04 9.299e-08 1.057e-07  3.385e-87
## 13664 7.224e-08 6.902e-14 7.690e-15 1.406e-111
## 3357  8.994e-01 2.395e-02 7.627e-02  4.517e-45
```

```r
preds2 <- predict(cylModel, type="class", newdata=vehiclesTest)
head(preds2)
```

```
## [1] 6 4 8 6 4 8
## Levels: 0 2 3 4 5 6 8 10 12 16
```

Choosing which of the two predictions will depend on your needs. If you just want your ``cylinders`` predictions, use ``class``, if you need to do anything more complex, like measure the conviction of each prediction, use the ``probs`` option (every row will add up to 1).
<BR><BR>

To check the <B>accuracy</B> of the model, we call the ``postResample`` function from <b>caret</b>. For numeric vectors, it uses the mean squared error and R-squared and for factors, the overall agreement rate and Kappa:

```r
postResample(vehiclesTest$cylinders,preds2)
```

```
## Accuracy    Kappa 
##   0.9034   0.8566
```
<BR><BR>
As a bonus, lets do some simple repeated cross validation to get a more comprehensive mean accuracy score and understand convergence. The code below will iterate through all the data to give every variable a chance of being <b>test</b> and <b>train</b> data sets. The first time around we set ``maxit`` to only <b>50</b>:

```r
totalAccuracy <- c()
cv <- 10
cvDivider <- floor(nrow(vehicles) / (cv+1))
 
for (cv in seq(1:cv)) {
  # assign chunk to data test
  dataTestIndex <- c((cv * cvDivider):(cv * cvDivider + cvDivider))
  dataTest <- vehicles[dataTestIndex,]
  # everything else to train
  dataTrain <- vehicles[-dataTestIndex,]
 
  cylModel <- multinom(cylinders~., data=dataTrain, maxit=50, trace=T) 
 
  pred <- predict(cylModel, newdata=dataTest, type="class")
 
  #  classification error
  cv_ac <- postResample(dataTest$cylinders, pred)[[1]]
  print(paste('Current Accuracy:',cv_ac,'for CV:',cv))
  totalAccuracy <- c(totalAccuracy, cv_ac)
}
```

```
## stopped after 50 iterations
## [1] "Current Accuracy: 0.62559542711972 for CV: 1"
...
## stopped after 50 iterations
## [1] "Current Accuracy: 0.650682756430613 for CV: 2"
...
## stopped after 50 iterations
## [1] "Current Accuracy: 0.613210543029533 for CV: 3"
...
## stopped after 50 iterations
## [1] "Current Accuracy: 0.657669101302001 for CV: 4"
...
## stopped after 50 iterations
## [1] "Current Accuracy: 0.607494442680216 for CV: 5"
...
## stopped after 50 iterations
## [1] "Current Accuracy: 0.644649094950778 for CV: 6"
...
## stopped after 50 iterations
## [1] "Current Accuracy: 0.70593839314068 for CV: 7"
...
## stopped after 50 iterations
## [1] "Current Accuracy: 0.621149571292474 for CV: 8"
...
## stopped after 50 iterations
## [1] "Current Accuracy: 0.59892029215624 for CV: 9"
...
## stopped after 50 iterations
## [1] "Current Accuracy: 0.62432518259765 for CV: 10"
```

```r
 mean(totalAccuracy)  
```

```
## [1] 0.635
```
The <b>mean accuracy</b> of <b>0.635</b> is much lower than the accuracy of <b>0.9034</b> that we got with the original simple split. You will notice that the log output never prints the word <b>converged</b>. This means the model never reaches the lowest error or global minima and therefore isn't the best fit. 
<BR><BR>
Let's try this again and let the model converge by setting the ``maxit`` to a large number


```r
totalAccuracy <- c()
cv <- 10
cvDivider <- floor(nrow(vehicles) / (cv+1))
 
for (cv in seq(1:cv)) {
  # assign chunk to data test
  dataTestIndex <- c((cv * cvDivider):(cv * cvDivider + cvDivider))
  dataTest <- vehicles[dataTestIndex,]
  # everything else to train
  dataTrain <- vehicles[-dataTestIndex,]
 
  cylModel <- multinom(cylinders~., data=dataTrain, maxit=1000, trace=T) 
 
  pred <- predict(cylModel, newdata=dataTest, type="class")
 
  #  classification error
  cv_ac <- postResample(dataTest$cylinders, pred)[[1]]
  print(paste('Current Accuracy:',cv_ac,'for CV:',cv))
  totalAccuracy <- c(totalAccuracy, cv_ac)
}
```

```
## converged
## [1] "Current Accuracy: 0.905366783105748 for CV: 1"

## converged
## [1] "Current Accuracy: 0.89838043823436 for CV: 2"

## converged
## [1] "Current Accuracy: 0.909812638932995 for CV: 3"

## converged
## [1] "Current Accuracy: 0.904096538583677 for CV: 4"

## converged
## [1] "Current Accuracy: 0.906637027627818 for CV: 5"
 
## converged
## [1] "Current Accuracy: 0.906001905366783 for CV: 6"

## converged
## [1] "Current Accuracy: 0.911400444585583 for CV: 7"

## converged
## [1] "Current Accuracy: 0.902508732931089 for CV: 8"

## converged
## [1] "Current Accuracy: 0.90377897745316 for CV: 9"
 
## converged
## [1] "Current Accuracy: 0.904414099714195 for CV: 10"
```

```r
mean(totalAccuracy)  

## [1] 0.9052
```
The score using the <b>repeated cross validation</b> code is better than the original simple split of <b>0.9304</b> and we let each loop converge. The point of using the <b>repeated cross validation</b> code isn't that it will return a higher accuracy score (and it doesn't always) but that it will give you a much more accurate score as it uses all of your data. 

<BR><BR>        
<a id="sourcecode">Full source code (<a href='https://github.com/amunategui/MultinomWalkThru' target='_blank'>also on GitHub</a>)</a>:

```r


library(nnet)
?multinom

library(caret)
library(RCurl)
library(Metrics)

#####################################################################
# Load data from Hadley Wickham on Github 
urlfile <-'https://raw.githubusercontent.com/hadley/fueleconomy/master/data-raw/vehicles.csv'
x <- getURL(urlfile, ssl.verifypeer = FALSE)
vehicles <- read.csv(textConnection(x))

# clean up the data and only use the first 24 columns
vehicles <- vehicles[names(vehicles)[1:24]]
vehicles <- data.frame(lapply(vehicles, as.character), stringsAsFactors=FALSE)
vehicles <- data.frame(lapply(vehicles, as.numeric))
vehicles[is.na(vehicles)] <- 0

# use cyclinder column as outcome and cast to factor
vehicles$cylinders <- as.factor(vehicles$cylinders)
table(vehicles$cylinders)
#####################################################################


# shuffle and split
set.seed(1234)
vehicles <- vehicles[sample(nrow(vehicles)),]
split <- floor(nrow(vehicles)/2)
vehiclesTrain <- vehicles[0:split,]
vehiclesTest <- vehicles[(split+1):nrow(vehicles),]


# see how multinom predicts cylinders
# set the maxit to a large number, enough so the neural net can converge to smallest error
cylModel <- multinom(cylinders~., data=vehiclesTrain, maxit=500, trace=T)

# Sort by most influential variables
topModels <- varImp(cylModel)
topModels$Variables <- row.names(topModels)
topModels <- topModels[order(-topModels$Overall),]

# class/probs (best option, second best option?)
preds1 <- predict(cylModel, type="probs", newdata=vehiclesTest)
preds2 <- predict(cylModel, type="class", newdata=vehiclesTest)

# resample for accuracy - the mean squared error and R-squared are calculated of forfactors, the overall agreement rate and Kappa
postResample(vehiclesTest$cylinders,preds2)[[1]]
preds

library(Metrics)
classificationError <- ce(as.numeric(vehiclesTest$cylinders), as.numeric(preds))

# repeat cross validate by iterating through all the data to give every variable a chance of being test and train portions
totalError <- c()
cv <- 10
maxiterations <- 500 # try it again with a lower value and notice the mean error
cvDivider <- floor(nrow(vehiclesTrain) / (cv+1))

for (cv in seq(1:cv)) {
        # assign chunk to data test
        dataTestIndex <- c((cv * cvDivider):(cv * cvDivider + cvDivider))
        dataTest <- vehiclesTrain[dataTestIndex,]
        # everything else to train
        dataTrain <- vehiclesTrain[-dataTestIndex,]
        
        cylModel <- multinom(cylinders~., data=dataTrain, maxit=maxiterations, trace=T) 
        
        pred <- predict(cylModel, dataTest)
        
        #  classification error
        err <- ce(as.numeric(dataTest$cylinders), as.numeric(pred))
        totalError <- c(totalError, err)
}
print(paste('Mean error of all repeated cross validations:',mean(totalError)))


```

