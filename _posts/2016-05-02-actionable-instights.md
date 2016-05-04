---
layout: post
title: "Actionable Insights: Getting Variable Importance at the Prediction Level in R"
category: Machine Learning
tags: exploring modeling r
year: 2016
month: 05
day: 02
published: true
summary: "Here is an easy way to get the top and bottom features contributing to a prediction. This affords a level of transparency to the report reader in understanding why the model chose a particular probability for an observation."
image: actionable-insights/ROBOT.png
---
<BR>
<p style="text-align:center">
<img src="../img/posts/actionable-insights/ROBOT.png" alt="actionable insights" style='padding:1px; border:1px solid #021a40; width: 30%; height: 30%'></p>

**Resources**
<ul>
<li type="square"><a href="https://www.youtube.com/user/mamunate/videos" target='_blank'>YouTube Companion Video</a></li>
</ul>
<BR><BR>
 
When we talk of variable importance we most often think of variables at the aggregate level of a supervised task. This is useful to understand a model at a high level but falls short in terms of actionable insight. Report readers want to know why a particular observation is given a particular probability - knowing full well that each prediction is a different situation. 

An easy way to extract the top variables for each observation is to simply cycle through each feature, average it to the population mean, and compare it to the original prediction. If the probability changes for that observation, then that feature has a strong effect for the observation. As probabilities share the same scale, we can measure the degree of change and sort each feature directionally. 

Let's see this through an example.

We'll use the <a href='https://archive.ics.uci.edu/ml/machine-learning-databases/pima-indians-diabetes' target='_blank'>Pima Indians Diabetes Database from the UCI Machine Learning Repository</a>. The data represents 768 patient observations and a series of medical measures to predict signs of diabetes. 

``` r

pima_db_names <- c('Number_times_pregnant', 'Plasma_glucose', 'Diastolic_blood_pressure', 
                   'Triceps_skin_fold_thickness','2_Hour_insulin', 'BMI', 'Diabetes_pedigree',
                   'Age', 'Class')

pima_db <- read.csv('https://archive.ics.uci.edu/ml/machine-learning-databases/pima-indians-diabetes/pima-indians-diabetes.data',
                    col.names = pima_db_names)


# removing obscure features
pima_db <- pima_db[,c("Number_times_pregnant", "Plasma_glucose", "Diastolic_blood_pressure","BMI", "Age", "Class")]

```
<BR><BR> 
Let's take a peek at the data:

``` r

dim(pima_db)

## [1] 767   6

head(pima_db)

##   Number_times_pregnant Plasma_glucose Diastolic_blood_pressure  BMI Age
## 1                     1             85                       66 26.6  31
## 2                     8            183                       64 23.3  32
## 3                     1             89                       66 28.1  21
## 4                     0            137                       40 43.1  33
## 5                     5            116                       74 25.6  30
## 6                     3             78                       50 31.0  26
##   Class
## 1     0
## 2     1
## 3     0
## 4     1
## 5     0
## 6     1

```
<BR><BR> 
The data is almost model-ready out of the box and we just need to split it into train/test sets:

``` r
set.seed(1234)
random_splits <- runif(nrow(pima_db))
train_df <- pima_db[random_splits < .5,]
dim(train_df)

## [1] 367   6

test_df <- pima_db[random_splits >= .5,]
dim(test_df)

## [1] 400   6

outcome_name <- 'Class'
```
<BR><BR>
To simplify things and maybe make this more useful for your advanced-analytics pipeline, we'll build our prediction insight program into a function. The modeling engine will use
<a href='https://cran.r-project.org/web/packages/xgboost/index.html' target='_blank'>xgboost: Extreme Gradient Boosting</a> because it is easy to use and fast. You will need to install ``xgboost`` and ``dplyr`` if you don't already have them (both available on cran).

``` r
observation_level_variable_importance <- function(train_data, live_data, outcome_name, eta = 0.2, 
                                                  max_depth=4, max_rounds=3000, number_of_factors=2) {
          
     # install.packages('dplyr')
     require(dplyr)
     # install.packages('xgboost')
     require(xgboost)
     
     set.seed(1234)
     split <- sample(nrow(train_data), floor(0.9*nrow(train_data)))
     train_data_tmp <- train_data[split,]
     val_data_tmp <- train_data[-split,]
     
     feature_names <- setdiff(names(train_data_tmp), outcome_name)
     dtrain <- xgb.DMatrix(data.matrix(train_data_tmp[,feature_names]), 
                           label=train_data_tmp[,outcome_name], missing=NaN)
     dval <- xgb.DMatrix(data.matrix(val_data_tmp[,feature_names]), 
                         label=val_data_tmp[,outcome_name], missing=NaN)
     watchlist <- list(eval = dval, train = dtrain)
     param <- list(  objective = "binary:logistic",
                     eta = eta,
                     max_depth = max_depth,
                     subsample= 0.9,
                     colsample_bytree= 0.9
     )
     
     xgb_model <- xgb.train ( params = param,
                              data = dtrain,
                              eval_metric = "auc",
                              nrounds = max_rounds,
                              missing=NaN,
                              verbose = 1,
                              print.every.n = 10,
                              early.stop.round = 20,
                              watchlist = watchlist,
                              maximize = TRUE)
     
     original_preditcions <- predict(xgb_model, 
                                     data.matrix(live_data[,feature_names]), 
                                     outputmargin=FALSE, missing=NaN)
      
     # strongest factors
     new_preds <- c()
     for (feature in feature_names) {
          print(feature)
          live_data_trsf <- live_data
          # neutralize feature to population mean
          if (sum(is.na(train_data[,feature])) > (nrow(train_data)/2)) {
               live_data_trsf[,feature] <- NA
          } else {
               live_data_trsf[,feature] <- mean(train_data[,feature], na.rm = TRUE)
          }
          predictions <- predict(object=xgb_model, data.matrix(live_data_trsf[,feature_names]),
                                 outputmargin=FALSE, missing=NaN)
          new_preds <- cbind(new_preds, original_preditcions-predictions)
     }
     
     positive_features <- c()
     negative_features <- c()
     
     feature_effect_df <- data.frame(new_preds)
     names(feature_effect_df) <- c(feature_names)
     
     for (pred_id in seq(nrow(feature_effect_df))) {
          vector_vals <- feature_effect_df[pred_id,]
          vector_vals <- vector_vals[,!is.na(vector_vals)]
          positive_features <- rbind(positive_features, 
                                     c(colnames(vector_vals)[order(vector_vals, 
                                                                   decreasing=TRUE)][1:number_of_factors]))
          negative_features <- rbind(negative_features, 
                                     c(colnames(vector_vals)[order(vector_vals, 
                                                                   decreasing=FALSE)][1:number_of_factors]))
     }
     
     positive_features <- data.frame(positive_features)
     names(positive_features) <- paste0('Pos_', names(positive_features))
     negative_features <- data.frame(negative_features)
     names(negative_features) <- paste0('Neg_', names(negative_features))
     
     return(data.frame(original_preditcions, positive_features, negative_features))
      
} 
```
<BR><BR> 
The first half of the function is straight-forward `xgboost` classification (see <a href='https://xgboost.readthedocs.io/en/latest/R-package/xgboostPresentation.html' target='_blank'>XGBoost R Tutorial</a>) and we get a vector of predictions for our test/live data. It is in the second half that things get more interesting - after the model has trained on the training data split and predicted on the testing split, we are left with the prediction vector - dubbed original predictions. It is a long series of probabilities, one for each observation. The model used here isn't important and the above should work with most models.

We then run through each feature a second time we reset the feature to the population mean. We feed that the new data set with its feature neutralized into the prediction function and compare the original prediction vector against this new one. Any time the prediction for an observation changes, we conclude it is important for that observation. We also record whether the original feature has a positive or negative influence on that prediction.

```
# get variable importance 

preds <- observation_level_variable_importance(train_data = train_df, 
                         live_data = test_df, 
                         outcome_name = outcome_name)

## Loading required package: dplyr

## 
## Attaching package: 'dplyr'

## The following objects are masked from 'package:stats':
## 
##     filter, lag

## The following objects are masked from 'package:base':
## 
##     intersect, setdiff, setequal, union

## Loading required package: xgboost

## 
## Attaching package: 'xgboost'

## The following object is masked from 'package:dplyr':
## 
##     slice

## Warning in xgb.train(params = param, data = dtrain, eval_metric = "auc", :
## Only the first data set in watchlist is used for early stopping process.

## [0]  eval-auc:0.800000   train-auc:0.841169
## [10] eval-auc:0.814815   train-auc:0.926103
## [20] eval-auc:0.818519   train-auc:0.948686
## [30] eval-auc:0.822222   train-auc:0.956050
## [40] eval-auc:0.803704   train-auc:0.965202
## Stopping. Best iteration: 25[1] "Number_times_pregnant"
## [1] "Plasma_glucose"
## [1] "Diastolic_blood_pressure"
## [1] "BMI"
## [1] "Age"

```
<BR><BR>
Let's take a look at the most extreme probabilities - ``Diastolic_blood_pressure`` is a strong influence for a low probability score, while ``Plasma_glucose`` is a strong influence for a high probability score:

``` r

preds <- preds[order(preds$original_preditcions),]
head(preds)

##     original_preditcions                   Pos_X1                   Pos_X2
## 42           0.003732002    Number_times_pregnant Diastolic_blood_pressure
## 346          0.003956458 Diastolic_blood_pressure    Number_times_pregnant
## 359          0.004147866 Diastolic_blood_pressure    Number_times_pregnant
## 274          0.004275108    Number_times_pregnant Diastolic_blood_pressure
## 13           0.004463046 Diastolic_blood_pressure    Number_times_pregnant
## 72           0.005090717    Number_times_pregnant Diastolic_blood_pressure
##     Neg_X1         Neg_X2
## 42     BMI            Age
## 346    BMI            Age
## 359    BMI            Age
## 274    BMI Plasma_glucose
## 13     BMI            Age
## 72     BMI            Age

tail(preds)

##     original_preditcions         Pos_X1                Pos_X2
## 129            0.9508100 Plasma_glucose Number_times_pregnant
## 248            0.9511197 Plasma_glucose                   BMI
## 203            0.9590986 Plasma_glucose Number_times_pregnant
## 71             0.9644873 Plasma_glucose                   Age
## 51             0.9722556 Plasma_glucose                   BMI
## 224            0.9739259 Plasma_glucose Number_times_pregnant
##                       Neg_X1                   Neg_X2
## 129                      BMI Diastolic_blood_pressure
## 248                      Age Diastolic_blood_pressure
## 203                      Age Diastolic_blood_pressure
## 71  Diastolic_blood_pressure                      BMI
## 51                       Age Diastolic_blood_pressure
## 224                      Age Diastolic_blood_pressure
```
<BR><BR>
To confirm this, let's use a Generalized Linear Model (`glm`) from <a href='http://caret.r-forge.r-project.org/' target='_blank'>caret</a> to access directional variable importance:

``` r
# install.packages('caret')

library(caret)

## Loading required package: lattice

## Loading required package: ggplot2

objControl <- trainControl(method='cv', number=3, returnResamp='none')

glm_caret_model <- train(train_df[,setdiff(names(train_df),outcome_name)], 
                         as.factor(ifelse(train_df[,outcome_name]==1,'yes','no')), 
                         method='glm', 
                         trControl=objControl,
                         preProc = c("center", "scale"))

summary(glm_caret_model)

## 
## Call:
## NULL
## 
## Deviance Residuals: 
##     Min       1Q   Median       3Q      Max  
## -2.2566  -0.6921  -0.3647   0.7062   2.3569  
## 
## Coefficients:
##                          Estimate Std. Error z value Pr(>|z|)    
## (Intercept)               -0.8444     0.1429  -5.911 3.41e-09 ***
## Number_times_pregnant      0.3025     0.1612   1.876  0.06067 .  
## Plasma_glucose             1.2242     0.1687   7.256 4.00e-13 ***
## Diastolic_blood_pressure  -0.3798     0.1452  -2.615  0.00893 ** 
## BMI                        0.7898     0.1647   4.795 1.62e-06 ***
## Age                        0.3843     0.1644   2.337  0.01941 *  
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## (Dispersion parameter for binomial family taken to be 1)
## 
##     Null deviance: 480.61  on 366  degrees of freedom
## Residual deviance: 338.16  on 361  degrees of freedom
## AIC: 350.16
## 
## Number of Fisher Scoring iterations: 5
```
<BR><BR>
In the ``Coefficients`` section, we confirm that ``Diastolic_blood_pressure`` has a negative influence on the outcome, while ``Plasma_glucose`` has a positive influence.

``` r
test_df[359,]

##     Number_times_pregnant Plasma_glucose Diastolic_blood_pressure  BMI Age
## 680                     2             56                       56 24.2  22
##     Class
## 680     0

test_df[71,]

##     Number_times_pregnant Plasma_glucose Diastolic_blood_pressure  BMI Age
## 154                     8            188                       78 47.9  43
##     Class
## 154     1

```
<BR><BR>
<b>Once again, thanks Lucas for the actionable insights explorer!!</b>