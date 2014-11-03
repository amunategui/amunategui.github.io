---
layout: post
title: Predicting Multiple Discrete Values with <b>Multinomials</b>, <b>Neural Networks</b> and the <b>{nnet}</b> Package
category: Machine Learning
tags: modeling
year: 2014
month: 11
day: 1
published: true
summary: Using the <b>multinom</b> function from the <b>nnet</b> package, we can easily predict discrete/factors of more than <b>2</b> levels. We also use <b>Repeated Cross Validation</b> to get an accurate model score and we understand the importance of allowing models to converge (reaching global minima).
image: multinom-neuralnetworks/converged.png
---
**Resources**
<ul>
<li type="square"><a href="https://www.youtube.com/watch?v=zTlbMHw9CeY" target='_blank'>YouTube Companion Video</a></li>
<li type="square"><a href="#sourcecode">Full Source Code</a></li>
</ul>
<BR>
**Packages Used in this Walkthrough**

<ul>
        <li type="square"><b>{nnet}</b> - neural network multinomial modeling</li>
        <li type="square"><b>{RCurl}</b> - downloads https data</li>
        <li type="square"><b>{caret}</b> - dummyVars function</li>
        <li type="square"><b>{Metrics}</b> - measuring error & AUC</li>
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

<blockquote>'Fits multinomial log-linear models via neural networks'</blockquote>
<BR><BR>
In a nutshell, this allows you to predict a factor of multiple levels (more than two) in one shot with the power of neural networks. <b>Neural networks</b> are great at working with combinations and also great with linear models so it's a perfect combination!

If your data is linear in nature, then instead of using multiple models and doing ``A`` versus ``B``, ``B`` versus ``C``, and ``C`` versus ``A``, let <b>nnet</b> do it all in one shot. And this becomes exponentialy more difficult when you're predicting more than 3 outcome levels! 

The ``multinom`` function will do all that for you in one shot and allow you to observe the probabilities of the prediction to interpret things (really cool). 

**Let's code!**
We're going to use a <b>Hadley Wickham</b> data set to predict how many cylinders a vehicle has. 

Load data from Hadley Wickham on Github 

```r
library(RCurl)
```

```
## Loading required package: bitops
```

```r
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
<BR><BR>
Finally shuffle the data and split it into two equal data frames:

```r
set.seed(1234)
vehicles <- vehicles[sample(nrow(vehicles)),]
split <- floor(nrow(vehicles)/2)
vehiclesTrain <- vehicles[0:split,]
vehiclesTest <- vehicles[(split+1):nrow(vehicles),]
```

<BR><BR>
Let's put <b>nnet</b> to work and predict cyclinders. The ``maxiter`` variable defaults to 100 when omitted so let's start with a large number the first around to make sure we find the lowest possible error level (i.e. global minimum - solution with the lowest error possible):


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
<BR><BR>
When you see the ``converged`` log output, you know the model went as far as it could.
<BR><BR>
Sort by most influential variables by using <b>caret's</b> ``varImp`` function:

```r
library(caret)
```

```
## Loading required package: lattice
## Loading required package: ggplot2
```

```r
topModels <- varImp(cylModel)
topModels$Variables <- row.names(topModels)
topModels <- topModels[order(-topModels$Overall),]
```
<BR><BR>
Next we predict ``cylinders`` using the ``predict`` function and our testing data set. There are two ways we can get our predictions, ``class`` or ``probs``:

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
<BR><BR>
The above two predictions will depend on your needs. If you just want the ``cylinders``, use ``class``.
<BR>
To check the <B>accuracy</B>, we call the ``postResample`` function from <b>caret</b>- the mean squared error and R-squared are calculated for numeric vectors and the overall agreement rate and Kappa for factors:

```r
postResample(vehiclesTest$cylinders,preds2)
```

```
## Accuracy    Kappa 
##   0.9034   0.8566
```
<BR><BR>
As a bonus, lets do some simple repeated cross validation to get a more comprehensive mean accuracy score. This will iterate through all the data to give every variable a chance of being <b>test</b> and <b>train</b> data sets:


```r
totalAccuracy <- c()
cv <- 10
cvDivider <- floor(nrow(vehiclesTrain) / (cv+1))
 
for (cv in seq(1:cv)) {
  # assign chunk to data test
  dataTestIndex <- c((cv * cvDivider):(cv * cvDivider + cvDivider))
  dataTest <- vehiclesTrain[dataTestIndex,]
  # everything else to train
  dataTrain <- vehiclesTrain[-dataTestIndex,]
 
  cylModel <- multinom(cylinders~., data=dataTrain, maxit=50, trace=T) 
 
  pred <- predict(cylModel, newdata=dataTest, type="class")
 
  #  classification error
  cv_ac <- postResample(dataTest$cylinders, pred)[[1]]
  print(paste('Current Accuracy:',cv_ac,'for CV:',cv))
  totalAccuracy <- c(totalAccuracy, cv_ac)
}
```

```
## # weights:  250 (216 variable)
## initial  value 36242.689364 
## iter  10 value 17575.749910
## iter  20 value 16508.520266
## iter  30 value 15285.279262
## iter  40 value 14403.957718
## iter  50 value 14259.966517
## final  value 14259.966517 
## stopped after 50 iterations
## [1] "Current Accuracy: 0.718730158730159 for CV: 1"
## # weights:  250 (216 variable)
## initial  value 36242.689364 
## iter  10 value 17742.164621
## iter  20 value 16568.266047
## iter  30 value 15473.611938
## iter  40 value 14490.119105
## iter  50 value 14219.752825
## final  value 14219.752825 
## stopped after 50 iterations
## [1] "Current Accuracy: 0.697142857142857 for CV: 2"
## # weights:  250 (216 variable)
## initial  value 36242.689364 
## iter  10 value 17640.715242
## iter  20 value 16587.162051
## iter  30 value 15276.640717
## iter  40 value 14537.944828
## iter  50 value 14379.971816
## final  value 14379.971816 
## stopped after 50 iterations
## [1] "Current Accuracy: 0.736507936507937 for CV: 3"
## # weights:  250 (216 variable)
## initial  value 36242.689364 
## iter  10 value 17646.575494
## iter  20 value 16639.410235
## iter  30 value 15144.987178
## iter  40 value 14385.915707
## iter  50 value 14267.965685
## final  value 14267.965685 
## stopped after 50 iterations
## [1] "Current Accuracy: 0.744761904761905 for CV: 4"
## # weights:  250 (216 variable)
## initial  value 36242.689364 
## iter  10 value 17637.982311
## iter  20 value 16625.486286
## iter  30 value 15476.544017
## iter  40 value 14571.859014
## iter  50 value 14328.624724
## final  value 14328.624724 
## stopped after 50 iterations
## [1] "Current Accuracy: 0.713650793650794 for CV: 5"
## # weights:  250 (216 variable)
## initial  value 36242.689364 
## iter  10 value 17623.681474
## iter  20 value 16558.085373
## iter  30 value 15196.968055
## iter  40 value 14244.539235
## iter  50 value 14009.759122
## final  value 14009.759122 
## stopped after 50 iterations
## [1] "Current Accuracy: 0.738412698412698 for CV: 6"
## # weights:  250 (216 variable)
## initial  value 36242.689364 
## iter  10 value 17566.807113
## iter  20 value 16546.372736
## iter  30 value 15498.436174
## iter  40 value 14047.675731
## iter  50 value 13794.314063
## final  value 13794.314063 
## stopped after 50 iterations
## [1] "Current Accuracy: 0.685714285714286 for CV: 7"
## # weights:  250 (216 variable)
## initial  value 36242.689364 
## iter  10 value 17586.390756
## iter  20 value 16580.063121
## iter  30 value 15245.398803
## iter  40 value 14230.231923
## iter  50 value 14038.906486
## final  value 14038.906486 
## stopped after 50 iterations
## [1] "Current Accuracy: 0.74031746031746 for CV: 8"
## # weights:  250 (216 variable)
## initial  value 36242.689364 
## iter  10 value 17447.847832
## iter  20 value 16416.997064
## iter  30 value 15220.575040
## iter  40 value 14790.881925
## iter  50 value 14677.685147
## final  value 14677.685147 
## stopped after 50 iterations
## [1] "Current Accuracy: 0.693333333333333 for CV: 9"
## # weights:  250 (216 variable)
## initial  value 36242.689364 
## iter  10 value 17593.831592
## iter  20 value 16560.625576
## iter  30 value 15253.058240
## iter  40 value 14191.781129
## iter  50 value 13998.934477
## final  value 13998.934477 
## stopped after 50 iterations
## [1] "Current Accuracy: 0.707936507936508 for CV: 10"
```

```r
 mean(totalAccuracy)  
```

```
## [1] 0.7177
```

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