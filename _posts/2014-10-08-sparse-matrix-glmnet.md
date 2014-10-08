---
layout: post
title: The Sparse Matrix and <B>{glmnet}</B>
category: Machine Learning
tags: modeling
year: 2014
month: 10
day: 08
published: true
summary: Walkthrough of sparse matrices in R and basic use of the glmnet package. This will show how to create them, find the best probabilities through the glmnet model, and how a sparse matrix deals with categorical values.
image: sparse-matrix-glmnet/sparse.png
---
<i><B>YouTube Companion Video:</B> <a href="https://www.youtube.com/watch?v=Ysh2gs8VKvQ&list=UUq4pm1i_VZqxKVVOz5qRBIA" target="_blank">Sparse Matrix and GLMNET: Machine Learning with R</a></i>
<BR><BR><BR>


In this walkthough, I am going to show how sparse matrices work in R and how to use them with the GLMNET package.

For those that aren't familiar with sparse matrices, or the sparse matrix, as the name implies, it is a large but ideally hollow data set. If your data contains lots of zeros then a sparse matrix is a very memory-efficient way of holding that data. For example, if you have a lot of dummy variables, most of that data will be zeros, and a sparse matrix will only hold non-zero data and ignore the zeros, thus using a lot less memory and allowing the memorization of much larger data sets than traditional data frames.

**Wikipedia** has great write-up on the <a href='http://en.wikipedia.org/wiki/Sparse_matrix' target='-blank'>sparse matrix and related theories</a> if you want to dive into this in more details. 

Unfortunately the sparse matrix in R doesn't accept **NAs**, **NaNs** and **Infinites**… Also, normalization functions, such as centering or scaling, could affect the zero values and render the data set into a non-sparse matrix and defeating any memory-efficient advantages.

Let's start with a simple data set called ``some_dataframe``:



```r
print(some_dataframe)
```

```
##    c1 c2 c3 c4 c5 c6 c7 c8 c9 c10 outcome
## 1   2  7  0  0  0  0  0  0  0   0       0
## 2   0  0  3  0  0  0  0  0  0   0       0
## 3   0  0  0  6  1  0  0  0  0   0       0
## 4   0  0  0  2  0  0  0  0  0   0       0
## 5   0  0  0  0  0  0  0  0 12   0       1
## 6   0  0  0  0  0 25  0  0  0   0       1
## 7   1  0  0  0  2  0  0  0  0   0       0
## 8   0  0  0  2  0  0  0  0  0   0       0
## 9   0  0  0  0  0  0  0  0 14   0       1
## 10  0  0  0  0  0 21  0  0  0   0       1
## 11  0  0  0  0  0  0 28  0  0   0       1
## 12  0  0  0  0  0  0  0 35  0   0       1
## 13  0  0  0  0  0  0  0  0 42   0       1
## 14  0  0  0  0  0  0  0  0  0  49       1
```
To see the above **data.frame** in a **matrix** format simply requires casting it to a matrix:

```r
some_matrix <- data.matrix(some_dataframe[1:10])
print(some_matrix)
```

```
##       c1 c2 c3 c4 c5 c6 c7 c8 c9 c10
##  [1,]  2  7  0  0  0  0  0  0  0   0
##  [2,]  0  0  3  0  0  0  0  0  0   0
##  [3,]  0  0  0  6  1  0  0  0  0   0
##  [4,]  0  0  0  2  0  0  0  0  0   0
##  [5,]  0  0  0  0  0  0  0  0 12   0
##  [6,]  0  0  0  0  0 25  0  0  0   0
##  [7,]  1  0  0  0  2  0  0  0  0   0
##  [8,]  0  0  0  2  0  0  0  0  0   0
##  [9,]  0  0  0  0  0  0  0  0 14   0
## [10,]  0  0  0  0  0 21  0  0  0   0
## [11,]  0  0  0  0  0  0 28  0  0   0
## [12,]  0  0  0  0  0  0  0 35  0   0
## [13,]  0  0  0  0  0  0  0  0 42   0
## [14,]  0  0  0  0  0  0  0  0  0  49
```

Visually, it isn't much different than the data frame (internally, a matrix is restricted to one data type only). In order to transform it into a sparse matrix, we load the **Matrix library**, call the ``Matrix`` function with the ``sparse`` flag set to true:

```r
library(Matrix)
print(Matrix(some_matrix, sparse=TRUE))
```

```
## 14 x 10 sparse Matrix of class "dgCMatrix"
```

```
##    [[ suppressing 10 column names 'c1', 'c2', 'c3' ... ]]
```

```
##                               
##  [1,] 2 7 . . .  .  .  .  .  .
##  [2,] . . 3 . .  .  .  .  .  .
##  [3,] . . . 6 1  .  .  .  .  .
##  [4,] . . . 2 .  .  .  .  .  .
##  [5,] . . . . .  .  .  . 12  .
##  [6,] . . . . . 25  .  .  .  .
##  [7,] 1 . . . 2  .  .  .  .  .
##  [8,] . . . 2 .  .  .  .  .  .
##  [9,] . . . . .  .  .  . 14  .
## [10,] . . . . . 21  .  .  .  .
## [11,] . . . . .  . 28  .  .  .
## [12,] . . . . .  .  . 35  .  .
## [13,] . . . . .  .  .  . 42  .
## [14,] . . . . .  .  .  .  . 49
```
And here we finally get a sense of its efficiency, it only retains the non-zero values!

**GLMNET package**<BR>
The help files describes the ``GLMNET`` package as a package containing 'extremely efficient procedures for fitting lasso or elastic-net regularization for linear regression, logistic and multinomial regression models, poisson regression and the Cox model and more (<a href="http://cran.r-project.org/web/packages/glmnet/index.html" target="_blank">from the help files</a>).

Unfortunately in R, few models support sparse matrices besides **GLMNET** (that I know of) therefore in conversations about modeling with R, when the subject of sparse matrices comes up, it is usually followed by the ``glmnet`` model. 

Let's start by splitting our ``some_dataframe`` in two parts: a 2/3 portion that will become our training data set and a 1/3 portion for our testing data set (always set the ``seed`` so random draws are reproducible):

```r
set.seed(2)
split <- sample(nrow(some_dataframe), floor(0.7*nrow(some_dataframe)))
train <-some_dataframe[split,]
test <- some_dataframe[-split,]
```

We then construct a sparse model matrix using the typical **R** formula:

```r
library(glmnet) 
```

```
## Loaded glmnet 1.9-8
```

```r
train_sparse <- sparse.model.matrix(~.,train[1:10])
test_sparse <- sparse.model.matrix(~.,test[1:10])
print(train_sparse)
```

```
## 9 x 11 sparse Matrix of class "dgCMatrix"
```

```
##    [[ suppressing 11 column names '(Intercept)', 'c1', 'c2' ... ]]
```

```
##                             
## 3  1 . . . 6 1  .  . .  .  .
## 10 1 . . . . . 21  . .  .  .
## 7  1 1 . . . 2  .  . .  .  .
## 2  1 . . 3 . .  .  . .  .  .
## 13 1 . . . . .  .  . . 42  .
## 9  1 . . . . .  .  . . 14  .
## 11 1 . . . . .  . 28 .  .  .
## 6  1 . . . . . 25  . .  .  .
## 14 1 . . . . .  .  . .  . 49
```

```r
print(test_sparse)
```

```
## 5 x 11 sparse Matrix of class "dgCMatrix"
```

```
##    [[ suppressing 11 column names '(Intercept)', 'c1', 'c2' ... ]]
```

```
##                           
## 1  1 2 7 . . . . .  .  . .
## 4  1 . . . 2 . . .  .  . .
## 5  1 . . . . . . .  . 12 .
## 8  1 . . . 2 . . .  .  . .
## 12 1 . . . . . . . 35  . .
```

We call the ``glmnet`` model and get our fit:

```r
fit <- glmnet(train_sparse,train[,11])
```

And call the ``predict`` function to get our probabilities:

```r
pred <- predict(fit, test_sparse, type="class")
print(head(pred[,1:5]))
```

```
##        s0     s1     s2     s3    s4
## 1  0.6667 0.6742 0.6815 0.6884 0.695
## 4  0.6667 0.6742 0.6815 0.6884 0.695
## 5  0.6667 0.6742 0.6815 0.6884 0.695
## 8  0.6667 0.6742 0.6815 0.6884 0.695
## 12 0.6667 0.6742 0.6815 0.6884 0.695
```

The reason it returns many probability sets is because **GLMNET** fits the model for different regularization parameters at the same time. In order to get help us choose the best one, we can to use function ``cv.glmnet``. This will use cross validation to find the fit with the smallest error. Let's call cv.glmnet and pass the results to the ``s`` paramter (the prenalty parameter) of the ``predict`` function:

```r
# use cv.glmnet to find best lambda/penalty - choosing small nfolds for cv due to… 
# s is the penalty parameter
cv <- cv.glmnet(train_sparse,train[,11],nfolds=3)
pred <- predict(fit, test_sparse,type="response", s=cv$lambda.min)
```

**NOTE**: the ``cv.glmnet`` returns various values that may be important for your modeling needs. In particular ``lambda.min`` and ``lambda.1se``. One is the smallest error and the other is the simplest error. Refer to the help files to get the best results for your needs.

```r
print(names(cv))
```

```
##  [1] "lambda"     "cvm"        "cvsd"       "cvup"       "cvlo"      
##  [6] "nzero"      "name"       "glmnet.fit" "lambda.min" "lambda.1se"
```

The data is made up so there isn't much point in trying to measure the predictions:

```r
print(pred)
```

```
##         1
## 1  0.9898
## 4  0.8306
## 5  0.9898
## 8  0.8306
## 12 0.9898
```
 
Let's see how the ``sparse.model.matrix`` function of the **Matrix** package handles discreet values. I added a categorical variable ``mood`` with two levels: ``happy`` and ``sad``:


```r
print(cat_dataframe)
```

```
##    c1 c2 c3 c4 c5 c6 c7 c8 c9 c10  mood outcome
## 1   2  7  0  0  0  0  0  0  0   0 happy       0
## 2   0  0  3  0  0  0  0  0  0   0 happy       0
## 3   0  0  0  6  1  0  0  0  0   0 happy       0
## 4   0  0  0  2  0  0  0  0  0   0 happy       0
## 5   0  0  0  0  0  0  0  0 12   0   sad       1
## 6   0  0  0  0  0 25  0  0  0   0   sad       1
## 7   1  0  0  0  2  0  0  0  0   0 happy       0
## 8   0  0  0  2  0  0  0  0  0   0 happy       0
## 9   0  0  0  0  0  0  0  0 14   0   sad       1
## 10  0  0  0  0  0 21  0  0  0   0   sad       1
## 11  0  0  0  0  0  0 28  0  0   0   sad       1
## 12  0  0  0  0  0  0  0 35  0   0   sad       1
## 13  0  0  0  0  0  0  0  0 42   0   sad       1
## 14  0  0  0  0  0  0  0  0  0  49   sad       1
```
We call the ``sparse.model.matrix`` function and we notice that it turned ``happy`` into 0's and ``sad`` into 1's. Thus, we only see the ones:

```r
sparse.model.matrix(~.,cat_dataframe)
```

```
## 14 x 13 sparse Matrix of class "dgCMatrix"
```

```
##    [[ suppressing 13 column names '(Intercept)', 'c1', 'c2' ... ]]
```

```
##                                  
## 1  1 2 7 . . .  .  .  .  .  . . .
## 2  1 . . 3 . .  .  .  .  .  . . .
## 3  1 . . . 6 1  .  .  .  .  . . .
## 4  1 . . . 2 .  .  .  .  .  . . .
## 5  1 . . . . .  .  .  . 12  . 1 1
## 6  1 . . . . . 25  .  .  .  . 1 1
## 7  1 1 . . . 2  .  .  .  .  . . .
## 8  1 . . . 2 .  .  .  .  .  . . .
## 9  1 . . . . .  .  .  . 14  . 1 1
## 10 1 . . . . . 21  .  .  .  . 1 1
## 11 1 . . . . .  . 28  .  .  . 1 1
## 12 1 . . . . .  .  . 35  .  . 1 1
## 13 1 . . . . .  .  .  . 42  . 1 1
## 14 1 . . . . .  .  .  .  . 49 1 1
```
Let's complicate things by adding a few more levels to our factor:   


```r
print(cat_dataframe)
```

```
##    c1 c2 c3 c4 c5 c6 c7 c8 c9 c10    mood outcome
## 1   2  7  0  0  0  0  0  0  0   0   angry       0
## 2   0  0  3  0  0  0  0  0  0   0 neutral       0
## 3   0  0  0  6  1  0  0  0  0   0   happy       0
## 4   0  0  0  2  0  0  0  0  0   0   happy       0
## 5   0  0  0  0  0  0  0  0 12   0     sad       1
## 6   0  0  0  0  0 25  0  0  0   0     sad       1
## 7   1  0  0  0  2  0  0  0  0   0   happy       0
## 8   0  0  0  2  0  0  0  0  0   0   happy       0
## 9   0  0  0  0  0  0  0  0 14   0     sad       1
## 10  0  0  0  0  0 21  0  0  0   0 neutral       1
## 11  0  0  0  0  0  0 28  0  0   0     sad       1
## 12  0  0  0  0  0  0  0 35  0   0     sad       1
## 13  0  0  0  0  0  0  0  0 42   0     sad       1
## 14  0  0  0  0  0  0  0  0  0  49     sad       1
```

```r
print(levels(cat_dataframe$mood))
```

```
## [1] "angry"   "happy"   "neutral" "sad"
```
We can check the dimensions of both sets:

```r
dim(cat_dataframe)
```

```
## [1] 14 12
```

```r
dim(sparse.model.matrix(~.,cat_dataframe))
```

```
## [1] 14 15
```
The sparse model broke out the 4 levels into 3 new columns. This is because it applied ``Full Rank`` to the set - you're either one of the 3 moods, if you're neither of the 3, then you're assumed to be the forth or ``angry`` in this case (<a href="http://amunategui.github.io/dummyVar-Walkthrough/" target="_blank">see my walkthrough on dummy variables for more information</a>):

```r
print(sparse.model.matrix(~.,cat_dataframe))
```

```
## 14 x 15 sparse Matrix of class "dgCMatrix"
```

```
##    [[ suppressing 15 column names '(Intercept)', 'c1', 'c2' ... ]]
```

```
##                                      
## 1  1 2 7 . . .  .  .  .  .  . . . . .
## 2  1 . . 3 . .  .  .  .  .  . . 1 . .
## 3  1 . . . 6 1  .  .  .  .  . 1 . . .
## 4  1 . . . 2 .  .  .  .  .  . 1 . . .
## 5  1 . . . . .  .  .  . 12  . . . 1 1
## 6  1 . . . . . 25  .  .  .  . . . 1 1
## 7  1 1 . . . 2  .  .  .  .  . 1 . . .
## 8  1 . . . 2 .  .  .  .  .  . 1 . . .
## 9  1 . . . . .  .  .  . 14  . . . 1 1
## 10 1 . . . . . 21  .  .  .  . . 1 . 1
## 11 1 . . . . .  . 28  .  .  . . . 1 1
## 12 1 . . . . .  .  . 35  .  . . . 1 1
## 13 1 . . . . .  .  .  . 42  . . . 1 1
## 14 1 . . . . .  .  .  .  . 49 . . 1 1
```
<BR><BR>
[Full Source](https://github.com/amunategui/Sparse-Matrices-And-GLMNET-Demo/blob/master/Sparse-Matrices-And-GLMNET-Demo.R):
```r

some_dataframe <- read.table(text="c1        c2     c3     c4     c5     c6     c7     c8     c9     c10     outcome
2     7     0     0     0     0     0     0     0     0     0
0     0     3     0     0     0     0     0     0     0     0
0     0     0     6     1     0     0     0     0     0     0
0     0     0     2     0     0     0     0     0     0     0
0     0     0     0     0     0     0     0     12     0     1
0     0     0     0     0     25     0     0     0     0     1
1     0     0     0     2     0     0     0     0     0     0
0     0     0     2     0     0     0     0     0     0     0
0     0     0     0     0     0     0     0     14     0     1
0     0     0     0     0     21     0     0     0     0     1
0     0     0     0     0     0     28     0     0     0     1
0     0     0     0     0     0     0     35     0     0     1
0     0     0     0     0     0     0     0     42     0     1
0     0     0     0     0     0     0     0     0     49     1", header=T, sep="") 

library(Matrix)
some_matrix <- data.matrix(some_dataframe[1:10])

# show matrix representation of data set
Matrix(some_matrix, sparse=TRUE)

# split data set into a train and test portion
set.seed(2)
split <- sample(nrow(some_dataframe), floor(0.7*nrow(some_dataframe)))
train <-some_dataframe[split,]
test <- some_dataframe[-split,]

# transform both sets into sparse matrices using the sparse.model.matrix
train_sparse <- sparse.model.matrix(~.,train[1:10])
test_sparse <- sparse.model.matrix(~.,test[1:10])

# model the sparse sets using glmnet
library(glmnet)  
fit <- glmnet(train_sparse,train[,11])

# use cv.glmnet to find best lambda/penalty 
# s is the penalty parameter
cv <- cv.glmnet(train_sparse,train[,11],nfolds=3)
pred <- predict(fit, test_sparse,type="response", s=cv$lambda.min)

#  receiver operating characteristic (ROC curves)
library(pROC)  
auc = roc(test[,11], pred)
print(auc$auc)

# how does sparse deal with categorical data (adding mood feature with two levels)?
cat_dataframe<- read.table(text="c1     c2     c3     c4     c5     c6     c7     c8     c9     c10     mood     outcome
2     7     0     0     0     0     0     0     0     0     happy     0
0     0     3     0     0     0     0     0     0     0     happy     0
0     0     0     6     1     0     0     0     0     0     happy     0
0     0     0     2     0     0     0     0     0     0     happy     0
0     0     0     0     0     0     0     0     12     0     sad     1
0     0     0     0     0     25     0     0     0     0     sad     1
1     0     0     0     2     0     0     0     0     0     happy     0
0     0     0     2     0     0     0     0     0     0     happy     0
0     0     0     0     0     0     0     0     14     0     sad     1
0     0     0     0     0     21     0     0     0     0     sad     1
0     0     0     0     0     0     28     0     0     0     sad     1
0     0     0     0     0     0     0     35     0     0     sad     1
0     0     0     0     0     0     0     0     42     0     sad     1
0     0     0     0     0     0     0     0     0     49     sad     1", header=T, sep="") 
print(sparse.model.matrix(~.,cat_dataframe))

# increasing the number of levels in the mood variable)
cat_dataframe <- read.table(text="c1     c2     c3     c4     c5     c6     c7     c8     c9     c10     mood     outcome
2     7     0     0     0     0     0     0     0     0     angry     0
0     0     3     0     0     0     0     0     0     0     neutral     0
0     0     0     6     1     0     0     0     0     0     happy     0
0     0     0     2     0     0     0     0     0     0     happy     0
0     0     0     0     0     0     0     0     12     0     sad     1
0     0     0     0     0     25     0     0     0     0     sad     1
1     0     0     0     2     0     0     0     0     0     happy     0
0     0     0     2     0     0     0     0     0     0     happy     0
0     0     0     0     0     0     0     0     14     0     sad     1
0     0     0     0     0     21     0     0     0     0     neutral     1
0     0     0     0     0     0     28     0     0     0     sad     1
0     0     0     0     0     0     0     35     0     0     sad     1
0     0     0     0     0     0     0     0     42     0     sad     1
0     0     0     0     0     0     0     0     0     49     sad     1", header=T, sep="") 
print(levels(cat_dataframe$mood))
dim(cat_dataframe)
# sparse added extra columns when in binarized mood
dim(sparse.model.matrix(~.,cat_dataframe))

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
