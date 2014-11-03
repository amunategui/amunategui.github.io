---
layout: post
title: Predicting Multiple Discrete Values with <b>Multinomials</b>, <b>Neural Networks</b> and the <b>{nnet}</b> Package
category: Machine Learning
tags: modeling
year: 2014
month: 11
day: 1
published: true
summary: Using the <b>multinom</b> function from the <b>nnet</b> package, we can easily predict discrete values (factors) of more than <b>2</b> levels. We also use <b>Repeated Cross Validation</b> to get an accurate model score and to understand the importance of allowing the model to converge (reaching global minima).
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

<blockquote>'Fits multinomial log-linear models via neural networks'</blockquote>

In a nutshell, this allows you to predict a factor of multiple levels (more than two) in one shot with the power of neural networks. <b>Neural networks</b> are great at working through multiple combinations and also great with linear models, so it's an ideal combination!

If your data is linear in nature, then instead of using multiple models and doing ``A`` versus ``B``, ``B`` versus ``C``, and ``C`` versus ``A``, and finally going through the hassle of concatenating the resulting probabilities, you can let <b>nnet</b> do it all in one shot. And this becomes exponentialy more difficult as you predict more than 3 outcome levels!! 

The ``multinom`` function will do all that for you in one shot and allow you to observe the probabilities of each subset to interpret things (now that's really cool). 
<BR><BR>
**Let's code!**

We're going to use a <a href='http://had.co.nz/' target='_blank'>Hadley Wickham</a> data set to predict how many cylinders a vehicle has. 

Load data from <a href='https://github.com/hadley' target='_blank'>Hadley Wickham</a> on Github 

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
<BR><BR>
Shuffle the data and split it into two equal data frames:

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
Let's sort by most influential variables by using <b>caret's</b> ``varImp`` function:

```r
library(caret)
mostImportantVariables <- varImp(cylModel)
mostImportantVariables$Variables <- row.names(mostImportantVariables)
mostImportantVariables <- mostImportantVariables[order(-mostImportantVariables$Overall),]
print(head(mostImportantVariables))
```
```
##             Overall  Variables
## charge240  625.5732  charge240
## cityUF     596.4079     cityUF
## combinedUF 580.1112 combinedUF
## displ      434.8038      displ
## cityE      395.3533      cityE
## combA08    322.2910    combA08
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
As a bonus, lets do some simple repeated cross validation to get a more comprehensive mean accuracy score and understand convergeance. The code below will iterate through all the data to give every variable a chance of being <b>test</b> and <b>train</b> data sets. The first time around we set ``maxit`` to only <b>50</b>:

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
You will notice that the log output never prints the word <b>converged</b>. This means the model never reaches the lowest error or global minima and therefore isn't the best fit.
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
 
  cylModel <- multinom(cylinders~., data=dataTrain, maxit=500, trace=T) 
 
  pred <- predict(cylModel, newdata=dataTest, type="class")
 
  #  classification error
  cv_ac <- postResample(dataTest$cylinders, pred)[[1]]
  print(paste('Current Accuracy:',cv_ac,'for CV:',cv))
  totalAccuracy <- c(totalAccuracy, cv_ac)
}
```

```
## # weights:  250 (216 variable)
## initial  value 72489.983898 
## iter  10 value 42774.601984
## iter  20 value 38671.630530
...
## iter 420 value 9213.112817
## iter 430 value 9212.558155
## final  value 9212.368137 
## converged
## [1] "Current Accuracy: 0.905366783105748 for CV: 1"

## stopped after 500 iterations
## [1] "Current Accuracy: 0.898062877103842 for CV: 2"

## stopped after 500 iterations
## [1] "Current Accuracy: 0.91044776119403 for CV: 3"
## # weights:  250 (216 variable)
## initial  value 72489.983898 
## iter  10 value 43774.399580
## iter  20 value 39393.784534
## iter  30 value 32778.900852
## iter  40 value 31402.984204
## iter  50 value 30534.457833
## iter  60 value 29144.525634
## iter  70 value 27725.994591
## iter  80 value 26536.515194
## iter  90 value 23356.455491
## iter 100 value 20404.104507
## iter 110 value 17960.352639
## iter 120 value 16013.838648
## iter 130 value 13826.380127
## iter 140 value 12249.732450
## iter 150 value 10408.292854
## iter 160 value 9767.569418
## iter 170 value 9479.289948
## iter 180 value 9281.143859
## iter 190 value 9240.263392
## iter 200 value 9216.662821
## iter 210 value 9201.424456
## iter 220 value 9184.623966
## iter 230 value 9176.128045
## iter 240 value 9168.825154
## iter 250 value 9164.547816
## iter 260 value 9159.014095
## iter 270 value 9148.282302
## iter 280 value 9140.119450
## iter 290 value 9135.645137
## iter 300 value 9133.734733
## iter 310 value 9132.589214
## iter 320 value 9131.816153
## iter 330 value 9130.669962
## iter 340 value 9129.569872
## iter 350 value 9128.694774
## iter 360 value 9127.562109
## iter 370 value 9126.454489
## iter 380 value 9125.917479
## iter 390 value 9125.537995
## iter 400 value 9124.909365
## iter 410 value 9124.319741
## iter 420 value 9123.829202
## iter 430 value 9123.114800
## iter 440 value 9122.613093
## iter 450 value 9122.531164
## iter 460 value 9122.467271
## iter 470 value 9122.316596
## iter 480 value 9122.213913
## iter 490 value 9122.179050
## iter 500 value 9122.143366
## final  value 9122.143366 
## stopped after 500 iterations
## [1] "Current Accuracy: 0.904096538583677 for CV: 4"
## # weights:  250 (216 variable)
## initial  value 72489.983898 
## iter  10 value 40578.291247
## iter  20 value 37111.154151
## iter  30 value 33898.657467
## iter  40 value 32517.696029
## iter  50 value 31786.870773
## iter  60 value 30738.911785
## iter  70 value 28864.009673
## iter  80 value 27510.267041
## iter  90 value 23686.264891
## iter 100 value 20181.814131
## iter 110 value 18341.148255
## iter 120 value 15460.315625
## iter 130 value 13628.662091
## iter 140 value 12541.081654
## iter 150 value 11306.673281
## iter 160 value 10195.355864
## iter 170 value 9794.620280
## iter 180 value 9473.095361
## iter 190 value 9353.548197
## iter 200 value 9325.308741
## iter 210 value 9298.152479
## iter 220 value 9274.840594
## iter 230 value 9257.965530
## iter 240 value 9247.165554
## iter 250 value 9239.823015
## iter 260 value 9233.341771
## iter 270 value 9224.921413
## iter 280 value 9220.896703
## iter 290 value 9216.496186
## iter 300 value 9214.753780
## iter 310 value 9213.576456
## iter 320 value 9212.927772
## iter 330 value 9212.579077
## iter 340 value 9212.206011
## iter 350 value 9211.925863
## iter 360 value 9211.629998
## iter 370 value 9211.023757
## iter 380 value 9210.591205
## iter 390 value 9210.136595
## iter 400 value 9209.788520
## iter 410 value 9209.355827
## iter 420 value 9208.467828
## iter 430 value 9207.864120
## iter 440 value 9207.609998
## iter 450 value 9207.593575
## iter 460 value 9207.561105
## iter 470 value 9207.417621
## iter 480 value 9207.055139
## iter 490 value 9206.204535
## iter 500 value 9205.096487
## final  value 9205.096487 
## stopped after 500 iterations
## [1] "Current Accuracy: 0.906319466497301 for CV: 5"
## # weights:  250 (216 variable)
## initial  value 72489.983898 
## iter  10 value 44603.208103
## iter  20 value 41556.147935
## iter  30 value 37986.743988
## iter  40 value 36100.078060
## iter  50 value 35162.457197
## iter  60 value 34235.272368
## iter  70 value 31427.021478
## iter  80 value 29839.496677
## iter  90 value 26465.957114
## iter 100 value 23942.673723
## iter 110 value 19761.213804
## iter 120 value 16693.518497
## iter 130 value 14819.577170
## iter 140 value 11554.646743
## iter 150 value 10599.185110
## iter 160 value 10032.125778
## iter 170 value 9620.126979
## iter 180 value 9434.264213
## iter 190 value 9360.934789
## iter 200 value 9329.443632
## iter 210 value 9296.627515
## iter 220 value 9277.370409
## iter 230 value 9266.049462
## iter 240 value 9258.642958
## iter 250 value 9252.391388
## iter 260 value 9245.752881
## iter 270 value 9240.098503
## iter 280 value 9235.960771
## iter 290 value 9232.951610
## iter 300 value 9230.345783
## iter 310 value 9228.856196
## iter 320 value 9227.234910
## iter 330 value 9225.087383
## iter 340 value 9222.996242
## iter 350 value 9222.033258
## iter 360 value 9221.369769
## iter 370 value 9220.430709
## iter 380 value 9219.338995
## iter 390 value 9218.813790
## iter 400 value 9218.078601
## iter 410 value 9217.528582
## iter 420 value 9216.814203
## iter 430 value 9216.152670
## iter 440 value 9216.003861
## iter 450 value 9215.955881
## iter 460 value 9215.888452
## iter 470 value 9215.809174
## iter 480 value 9215.335426
## iter 490 value 9214.986149
## iter 500 value 9214.520714
## final  value 9214.520714 
## stopped after 500 iterations
## [1] "Current Accuracy: 0.905366783105748 for CV: 6"
## # weights:  250 (216 variable)
## initial  value 72489.983898 
## iter  10 value 42901.270671
## iter  20 value 39612.410649
## iter  30 value 34786.732572
## iter  40 value 32292.476253
## iter  50 value 31022.368953
## iter  60 value 29394.150926
## iter  70 value 26864.847379
## iter  80 value 23754.845145
## iter  90 value 21346.080348
## iter 100 value 19502.746678
## iter 110 value 17292.725708
## iter 120 value 15267.749855
## iter 130 value 13349.390463
## iter 140 value 11618.137618
## iter 150 value 10921.949865
## iter 160 value 9984.284707
## iter 170 value 9677.095708
## iter 180 value 9506.385047
## iter 190 value 9447.286028
## iter 200 value 9418.669542
## iter 210 value 9389.102883
## iter 220 value 9357.256484
## iter 230 value 9334.160913
## iter 240 value 9324.708563
## iter 250 value 9317.302957
## iter 260 value 9310.866594
## iter 270 value 9303.962473
## iter 280 value 9301.516615
## iter 290 value 9300.138041
## iter 300 value 9298.163503
## iter 310 value 9295.944453
## iter 320 value 9294.111345
## iter 330 value 9293.237891
## iter 340 value 9292.642792
## iter 350 value 9292.197338
## iter 360 value 9291.784402
## iter 370 value 9291.415879
## iter 380 value 9291.049978
## iter 390 value 9289.807668
## iter 400 value 9288.911645
## iter 410 value 9288.254589
## iter 420 value 9287.531487
## iter 430 value 9285.854963
## iter 440 value 9285.302573
## iter 450 value 9285.237610
## iter 460 value 9285.161312
## iter 470 value 9284.911263
## iter 480 value 9284.486409
## iter 490 value 9283.944741
## iter 500 value 9283.186136
## final  value 9283.186136 
## stopped after 500 iterations
## [1] "Current Accuracy: 0.912035566846618 for CV: 7"
## # weights:  250 (216 variable)
## initial  value 72489.983898 
## iter  10 value 45741.566226
## iter  20 value 39797.676249
## iter  30 value 34977.107924
## iter  40 value 33416.623249
## iter  50 value 32160.843428
## iter  60 value 31055.747320
## iter  70 value 29756.817039
## iter  80 value 26105.374757
## iter  90 value 23237.627711
## iter 100 value 20301.833847
## iter 110 value 18344.311219
## iter 120 value 15365.838991
## iter 130 value 13469.417174
## iter 140 value 12149.446060
## iter 150 value 10781.113896
## iter 160 value 10112.667925
## iter 170 value 9653.963245
## iter 180 value 9418.681140
## iter 190 value 9355.698234
## iter 200 value 9325.033033
## iter 210 value 9302.018924
## iter 220 value 9285.513621
## iter 230 value 9271.212283
## iter 240 value 9257.664490
## iter 250 value 9248.164759
## iter 260 value 9240.021126
## iter 270 value 9231.167920
## iter 280 value 9219.969631
## iter 290 value 9214.020569
## iter 300 value 9211.641829
## iter 310 value 9210.038848
## iter 320 value 9208.822442
## iter 330 value 9208.510388
## iter 340 value 9208.338849
## iter 350 value 9208.114480
## iter 360 value 9208.021383
## iter 370 value 9207.970681
## iter 380 value 9207.927393
## iter 390 value 9207.849462
## iter 400 value 9207.789120
## iter 410 value 9207.732664
## iter 420 value 9207.617425
## iter 430 value 9207.535804
## iter 440 value 9207.493258
## iter 450 value 9207.479143
## iter 460 value 9207.460636
## iter 470 value 9207.427280
## iter 480 value 9207.336592
## iter 490 value 9207.117544
## iter 500 value 9206.482274
## final  value 9206.482274 
## stopped after 500 iterations
## [1] "Current Accuracy: 0.902508732931089 for CV: 8"
## # weights:  250 (216 variable)
## initial  value 72489.983898 
## iter  10 value 45796.400979
## iter  20 value 40923.047791
## iter  30 value 34935.351716
## iter  40 value 32996.583259
## iter  50 value 32595.223169
## iter  60 value 31388.976328
## iter  70 value 29339.065768
## iter  80 value 25477.118401
## iter  90 value 23546.292551
## iter 100 value 20767.360293
## iter 110 value 18518.716918
## iter 120 value 15660.307465
## iter 130 value 13643.491263
## iter 140 value 11608.266670
## iter 150 value 10597.917709
## iter 160 value 10032.707755
## iter 170 value 9521.516758
## iter 180 value 9377.879716
## iter 190 value 9322.510317
## iter 200 value 9291.026770
## iter 210 value 9266.565458
## iter 220 value 9251.441400
## iter 230 value 9241.160563
## iter 240 value 9232.914408
## iter 250 value 9224.639148
## iter 260 value 9220.543049
## iter 270 value 9217.542769
## iter 280 value 9214.340864
## iter 290 value 9212.003795
## iter 300 value 9210.487566
## iter 310 value 9209.219192
## iter 320 value 9208.042043
## iter 330 value 9206.884024
## iter 340 value 9205.909576
## iter 350 value 9205.068851
## iter 360 value 9204.286054
## iter 370 value 9203.442394
## iter 380 value 9202.445080
## iter 390 value 9201.811086
## iter 400 value 9201.416491
## iter 410 value 9201.008523
## iter 420 value 9200.187330
## iter 430 value 9199.302265
## iter 440 value 9198.874295
## iter 450 value 9198.821354
## iter 460 value 9198.734168
## iter 470 value 9198.511724
## iter 480 value 9198.008671
## iter 490 value 9197.537626
## iter 500 value 9196.989715
## final  value 9196.989715 
## stopped after 500 iterations
## [1] "Current Accuracy: 0.903461416322642 for CV: 9"
## # weights:  250 (216 variable)
## initial  value 72489.983898 
## iter  10 value 42893.738887
## iter  20 value 39920.652460
## iter  30 value 35633.174673
## iter  40 value 33749.121153
## iter  50 value 33325.418645
## iter  60 value 32283.655355
## iter  70 value 30211.969856
## iter  80 value 28511.098983
## iter  90 value 25833.420220
## iter 100 value 23311.693517
## iter 110 value 19364.163008
## iter 120 value 16402.830400
## iter 130 value 13570.113111
## iter 140 value 11351.042064
## iter 150 value 10121.471290
## iter 160 value 9719.575540
## iter 170 value 9509.727158
## iter 180 value 9328.485939
## iter 190 value 9299.611808
## iter 200 value 9271.896670
## iter 210 value 9249.901139
## iter 220 value 9231.120793
## iter 230 value 9222.277496
## iter 240 value 9215.798448
## iter 250 value 9212.410094
## iter 260 value 9209.411488
## iter 270 value 9204.988018
## iter 280 value 9201.145986
## iter 290 value 9194.896839
## iter 300 value 9191.603178
## iter 310 value 9190.110963
## iter 320 value 9189.114050
## iter 330 value 9188.302464
## iter 340 value 9187.377067
## iter 350 value 9186.458524
## iter 360 value 9185.716569
## iter 370 value 9185.250434
## iter 380 value 9184.883680
## iter 390 value 9184.420571
## iter 400 value 9183.712115
## iter 410 value 9182.962690
## iter 420 value 9182.258583
## iter 430 value 9181.746218
## iter 440 value 9181.292696
## iter 450 value 9181.240386
## iter 460 value 9181.224349
## iter 470 value 9181.141412
## iter 480 value 9181.064089
## iter 490 value 9180.841138
## iter 500 value 9180.479790
## final  value 9180.479790 
## stopped after 500 iterations
## [1] "Current Accuracy: 0.904096538583677 for CV: 10"
```

```r
 mean(totalAccuracy)  
```

```
## [1] 0.9052
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