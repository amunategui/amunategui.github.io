
# functions ---------------------------------------------------------------


XGboost_ForwardVarSelect2 <- function(objTrain, outcomeName, orderedVarimpList, max_depth=2, fullrounds=1) {
        require(caret)
        require(xgboost)
        require(ROCR)
        
        set.seed(1234)
        split <- sample(nrow(objTrain), floor(0.5*nrow(objTrain)))
        
        train <-objTrain[split,]
        test <- objTrain[-split,]
        
        #orderedVarimpList <- orderedVarimpList[1:10]
        
        varlist <- c()
        varlistAUC <- c()
        
        
        objTrainOutcome <- train[,outcomeName]
        objTestOutcome <- test[,outcomeName]
        
        # start by getting reference AUC
        bst = xgboost(data = as.matrix(train[orderedVarimpList[1]]),
                      label = as.matrix(objTrainOutcome),
                      verbose=0,
                      max_depth=max_depth,
                      nround =fullrounds,
                      objective="binary:logistic")
        
        predictions <- predict(bst, as.matrix(test[orderedVarimpList[1]]), outputmargin=FALSE)
        
        pred <- prediction(predictions, objTestOutcome) 
        refAUC <- performance(pred, "auc")@y.values[[1]]
        
        gc()  
        
        keeperlist <- c(orderedVarimpList[1])
        bestvars <- c(orderedVarimpList[1])
        
        
        #      for (flip in seq(1:2)) {
        
        # add each variable one at a time and keep it doesn't hurt score
        
        varlistCount <- length(orderedVarimpList)
        
        counter <- 1
        firstTopAUC <- 0
        
        for (looptime in seq(1:10)) {
                
                if (length(keeperlist) == 1) {
                        # first run
                } else {
                        
                        # get highest
                        if (length(varlist) > 0){
                                tempdf <- data.frame(varlist=varlist, varlistAUC=varlistAUC)
                                tempdf$varlist <- as.character(tempdf$varlist)
                                tempdf <- tempdf[order(tempdf$varlistAUC, decreasing=TRUE),]
                                
                                bestvars <- c(bestvars, tempdf$varlist[1])
                        } else {
                                print('nothing more to process')
                                return(keeperlist)
                        }
                        
                        # start by getting reference AUC
                        bst = xgboost(data = as.matrix(train[bestvars]),
                                      label = as.matrix(objTrainOutcome),
                                      verbose=0,
                                      max_depth=max_depth,
                                      nround =fullrounds,
                                      objective="binary:logistic")
                        
                        predictions <- predict(bst, as.matrix(test[bestvars]), outputmargin=FALSE)
                        
                        pred <- prediction(predictions, objTestOutcome) 
                        refAUC <- performance(pred, "auc")@y.values[[1]]
                        
                        
                        gc()  
                        
                        varlist <- c()
                        varlistAUC <- c()
                }
                print(paste('Trying for:', paste(bestvars,sep=" ", collapse=" "), 'ref AUC:', refAUC))
                
                
                for (varname in orderedVarimpList[!orderedVarimpList %in% bestvars]) {
                        objTrain_Temp <- train[c(bestvars, varname)]
                        objTest_Temp <- test[c(bestvars, varname)]
                        
                        bst = tryCatch({
                                xgboost(data = as.matrix(objTrain_Temp),
                                        label = as.matrix(objTrainOutcome),
                                        #min_child_weight=minchildweight,
                                        verbose=0,
                                        max_depth=max_depth,
                                        #subsample=subsampleset,
                                        nround =fullrounds,
                                        objective="binary:logistic")
                        }, error = function(e) {
                                print(e)
                                NULL
                        })
                        
                        if (!is.null(bst)) {
                                
                                predictions <- predict(bst, as.matrix(objTest_Temp), outputmargin=FALSE)
                                
                                pred <- prediction(predictions, objTestOutcome) 
                                curAUC <- performance(pred, "auc")@y.values[[1]]
                                #                     if (firstTopAUC < curAUC)
                                #                          firstTopAUC = curAUC
                                print(paste(counter, 'of',varlistCount))
                                
                                if (curAUC >= refAUC) {
                                        varlist <- c(varlist, varname)
                                        varlistAUC <- c(varlistAUC, curAUC)
                                        
                                        keeperlist <- c(keeperlist, varname)
                                        print(paste('size:', length(keeperlist), 'new auc:', curAUC, 'added:',varname))
                                }
                                
                                keeperlist <- unique(keeperlist)
                        }
                        gc()  
                        counter <- counter + 1
                        
                        #update best var list
                        
                        #           }
                        #           # flip test and train to crudely cover more data
                        #           temptrain <- train
                        #           train <- test
                        #           test <- temptrain
                        #           minchildweight <- 0.5
                        #           subsampleset <- 0.5
                        #           rounds <- 10
                        #           prevAUC <- 0
                        
                }
        }
        
        
        return (keeperlist)
}


XGboost_ForwardVarSelect <- function(objTrain, outcomeName, orderedVarimpList, max_depth=2, fullrounds=1) {
        require(caret)
        require(xgboost)
        require(ROCR)
        prevAUC <- 0
        minchildweight <- 1
        subsampleset <- 1
        rounds <- 2
        
        set.seed(1234)
        split <- sample(nrow(objTrain), floor(0.5*nrow(objTrain)))
        
        train <-objTrain[split,]
        test <- objTrain[-split,]
        
        keeperlist <- c()
        for (flip in seq(1:2)) {
                
                # add each variable one at a time and keep it doesn't hurt score
                
                objTrainOutcome <- train[,outcomeName]
                objTestOutcome <- test[,outcomeName]
                varlistCount <- length(orderedVarimpList)
                topName <- orderedVarimpList[1]
                counter <- 1
                firstTopAUC <- 0
                for (varname in orderedVarimpList) {
                        objTrain_Temp <- train[c(topName)]
                        objTest_Temp <- test[c(topName)]
                        
                        bst = tryCatch({
                                xgboost(data = as.matrix(objTrain_Temp),
                                        label = as.matrix(objTrainOutcome),
                                        #min_child_weight=minchildweight,
                                        verbose=0,
                                        max_depth=max_depth,
                                        #subsample=subsampleset,
                                        nround =rounds,
                                        objective="binary:logistic")
                        }, error = function(e) {
                                print(e)
                                NULL
                        })
                        
                        if (!is.null(bst)) {
                                
                                predictions <- predict(bst, as.matrix(objTest_Temp), outputmargin=FALSE)
                                
                                pred <- prediction(predictions, objTestOutcome) 
                                curAUC <- performance(pred, "auc")@y.values[[1]]
                                if (firstTopAUC < curAUC)
                                        firstTopAUC = curAUC
                                print(paste(counter, 'of',varlistCount))
                                
                                if (curAUC > firstTopAUC) {
                                        keeperlist <- c(keeperlist, varname)
                                        print(paste('size:', length(keeperlist), 'new auc:', curAUC, 'added:',varname))
                                }
                                
                                keeperlist <- unique(keeperlist)
                        }
                        gc()  
                        counter <- counter + 1
                }
                # flip test and train to crudely cover more data
                temptrain <- train
                train <- test
                test <- temptrain
                minchildweight <- 0.5
                subsampleset <- 0.5
                rounds <- 10
                prevAUC <- 0
        }
        print(paste('Final AUC:', prevAUC ))
        return (keeperlist)
}

RemoveHighCorrelation <- function(objDF, labelName=NULL, cutoff=0.95, silent=T) {
        # cutoff - A numeric value for the pariwise absolute correlation cutoff
        require(caret)
        if (!is.null(labelName)){
                labelData <- objDF[,labelName]
                predictors <- names(objDF)[names(objDF) != labelName]
                objDF <- objDF[,predictors]
        }
        
        descrCor<-cor(objDF)
        highlyCorDescr<-findCorrelation(descrCor, cutoff=cutoff, verbose = !silent)
        
        if (silent==F)
                print(highlyCorDescr)
        if (length(highlyCorDescr) > 0)
                objDF<-objDF[,-highlyCorDescr]
        
        if (!is.null(labelName)){
                objDF[,labelName] <- labelData}
        return(objDF)
}

XGboostVarImportance <- function(objTrain, objTest, outcomeName, colbags = c(1,3,5), 
                                 addRandomLayerCols = FALSE, colsample_bytree=1, 
                                 balanceoutcome=FALSE, verbose=FALSE, roundsForboosting=5)  {
        require(caret)
        require(xgboost)
        require(ROCR)
        
        # transform all integers to numericals
        ind <- sapply(objTrain, is.integer)
        objTrain[ind] <- lapply(objTrain[ind], as.numeric) 
        ind <- sapply(objTest, is.integer)
        objTest[ind] <- lapply(objTest[ind], as.numeric) 
        
        objTestOutcome <- objTest[,outcomeName]
        objTrainOutcome <- objTrain[,outcomeName]
        
        objTrain <- objTrain[,!names(objTrain) %in% outcomeName]
        objTest <- objTest[,!names(objTest) %in% outcomeName]
        
        predictoroutcomenames <- NULL
        predictoroutcomeresults <- NULL
        
        
        for (colbag in colbags) {
                
                colindexes <- split(seq_along(colnames(objTrain)), ceiling(seq_along(colnames(objTrain))/colbag))
                if (addRandomLayerCols) {
                        set.seed(1234)
                        # randomize colum indexes
                        colindexes <- c(colindexes,split(sample(unlist(colindexes, use.names=FALSE)), 
                                                         cumsum(sequence(sapply(colindexes, length))==1)))
                }
                
                # loop by columns first
                for (colind in colindexes) {
                        print(paste('colind',min(colind),'-',max(colind)))
                        
                        bst = tryCatch({
                                xgboost(data = as.matrix(objTrain[colind]),
                                        label = as.matrix(objTrainOutcome),
                                        verbose=0,
                                        eta = 0.5, # 0.1
                                        gamma = 1, #1.71,
                                        lambda= 0.5, #1,
                                        nround = 5,
                                        colsample_bytree = colsample_bytree,  
                                        objective="binary:logistic")
                        }, error = function(e) {
                                print(e)
                                NULL
                        })
                        
                        
                        if (!is.null(bst)) {
                                print('predicting')
                                predictions <- predict(bst, as.matrix(objTest[colind]), outputmargin=FALSE)
                                
                                pred <- prediction(predictions, objTestOutcome) 
                                AUC <- performance(pred, "auc")@y.values[[1]]
                                
                                predictorNames <- names(objTrain[colind])
                                print(paste('AUC score:', AUC,' Column evaluated:',predictorNames))
                                
                                for (predname in predictorNames) {
                                        
                                        predictoroutcomenames <- c(predictoroutcomenames,predname)
                                        predictoroutcomeresults <- c(predictoroutcomeresults,AUC)
                                }
                                
                        } else {
                                print('No variance - skipping')
                                predictorNames <- names(objTrain[colind])
                                for (predname in predictorNames) {
                                        predictoroutcomenames <- c(predictoroutcomenames,predname)
                                        predictoroutcomeresults <- c(predictoroutcomeresults,0.5)
                                }
                        }
                        gc()    
                }
        }
        return(data.frame("predictoroutcomenames"=predictoroutcomenames,"predictoroutcomeresults"=predictoroutcomeresults))
}


GetXGboostVarImportancev2 <- function(objTrain, outcomeName, colbags = c(1,3,5), addRandomLayerCols = FALSE, 
                                      colsample_bytree=1, balanceoutcome=F, verbose=F, roundsForboosting=5) {
        
        set.seed(1234)
        split <- sample(nrow(objTrain), floor(0.5*nrow(objTrain)))
        train <-objTrain[split,]
        test <- objTrain[-split,]
        
        vareval1 <- XGboostVarImportance(train,test,outcomeName,colbags=colbags, addRandomLayerCols=addRandomLayerCols, 
                                         colsample_bytree=colsample_bytree, roundsForboosting = roundsForboosting)
        vareval2 <- XGboostVarImportance(test, train, outcomeName,colbags=colbags, addRandomLayerCols=addRandomLayerCols, 
                                         colsample_bytree=colsample_bytree, roundsForboosting=roundsForboosting)
        both <- rbind(vareval1, vareval2)
        both <- aggregate(.~predictoroutcomenames,data=both, FUN=mean) 
        return (both[order(both$predictoroutcomeresults, decreasing = TRUE), ])
}


round_df <- function(x, digits) {
        # round all numeric variables
        # x: data frame 
        # digits: number of digits to round
        numeric_columns <- sapply(x, mode) == 'numeric'
        x[numeric_columns] <-  round(x[numeric_columns], digits)
        x
}


ExhaustiveBaggerV7 <- function(objTrain, objTest, outcomeName, TreeDepth=1, 
                               BootstingRounds = 150, balanceoutcome=F, verbose=F,
                               RowBaggingIterations=50, 
                               RowBaggingLengthDivisor=4, SizeIncrement=c(0.1,0.5,1)) {
        require(caret)
        require(xgboost)
        require(ROCR)
        require(foreach)
        
        # transform all integers to numericals
        ind <- sapply(objTrain, is.integer)
        objTrain[ind] <- lapply(objTrain[ind], as.numeric)
        ind <- sapply(objTest, is.integer)
        objTest[ind] <- lapply(objTest[ind], as.numeric)
        
        outcomeDF <- objTrain[,outcomeName]
        objTrain <- objTrain[!names(objTrain) %in% outcomeName]
        
        masterPredictions <- NULL
        predictorNames <-  intersect(names(objTrain), names(objTest))
        
        tempObjTrain <- as.data.frame(cbind(objTrain, outcomeDF))
        
        # loop by columns first
        for (coltree in SizeIncrement) {
                print(paste('coltree',coltree))
                for (subsampl in SizeIncrement) {
                        print(paste('subsample',subsampl))
                        
                        predictions <-foreach(m=1:RowBaggingIterations,.combine=cbind) %do% { 
                                #print(paste('bagset:',m))
                                training_positions <- sample(nrow(tempObjTrain),
                                                             size=floor((nrow(tempObjTrain)/RowBaggingLengthDivisor))) 
                                
                                train_pos<-1:nrow(tempObjTrain) %in% training_positions 
                                
                                tempBaggedObjTrain <- tempObjTrain[train_pos,]
                                
                                
                                if (balanceoutcome) {
                                        # give this a 50/50 balance with outcome
                                        balanceSize <- floor(nrow(tempBaggedObjTrain) / 2)
                                        
                                        dfPos <- tempBaggedObjTrain[tempObjTrain$outcomeDF==1,]
                                        dfPosCount <- nrow(dfPos)
                                        
                                        if (dfPosCount < balanceSize) {
                                                missingCount <- (balanceSize - dfPosCount)
                                                # create sample of pos observation not in current set
                                                dfPos_other <- tempObjTrain[-train_pos,]
                                                dfPos_other <- dfPos_other[dfPos_other$outcomeDF==1,]
                                                
                                                # if not enough size, take all
                                                if (nrow(dfPos_other) < missingCount) {
                                                        print('Adding all positives to balance')
                                                        tempBaggedObjTrain <- rbind(tempBaggedObjTrain,dfPos_other)
                                                } else {
                                                        print('Adding some new positives to balance')
                                                        set.seed(1234)
                                                        tempBaggedObjTrain <- rbind(tempBaggedObjTrain,dfPos_other[sample(nrow(dfPos_other),missingCount),])
                                                }
                                                set.seed(1234)
                                                tempBaggedObjTrain <- tempBaggedObjTrain[sample(nrow(tempBaggedObjTrain)),]
                                        }
                                        print(paste('after balance: nrow(tempBaggedObjTrain)',nrow(tempBaggedObjTrain)))
                                        
                                }
                                
                                bst = tryCatch({
                                        xgboost(data = as.matrix(tempBaggedObjTrain[,predictorNames]),
                                                label = tempBaggedObjTrain$outcomeDF,
                                                verbose=0,
                                                eta = 0.5, # 0.1
                                                gamma = 1, #1.71,
                                                lambda= 0.5, #1,
                                                max_depth=TreeDepth, #50, # maximum depth of a tree
                                                nround = BootstingRounds, #150, the number of round to do boosting
                                                subsample = subsampl, # subsample ratio of the training instance. Setting it to 0.5 means that XGBoost randomly collected half of the data instances to grow trees and this will prevent overfitting.
                                                colsample_bytree = coltree, # x% columns are randomly selected to build trees
                                                objective="binary:logistic")
                                }, error = function(e) {
                                        print(e)
                                        NULL
                                })
                                
                                if (!is.null(bst)) {
                                        #print('predicting')
                                        predictions <- predict(bst, as.matrix(objTest[,predictorNames]), outputmargin=FALSE)
                                } else {
                                        print('No variance - skipping')
                                        predictions <- rep(0.5,nrow(objTest))
                                }
                        }
                        gc()
                } 
                
                
                # sum them up and keep count of them
                rowcounts <- ncol(predictions)
                if (is.null(masterPredictions)) {
                        masterPredictions <- data.frame('SummedPreds'=rowSums(predictions))
                        #colnames(masterPredictions) <- c(paste0('SummedPreds',rowcounts))
                        masterPredictions$count <- rowcounts
                } else {
                        masterPredictions$SummedPreds <- masterPredictions$SummedPreds + rowSums(predictions) 
                        masterPredictions$count <- masterPredictions$count + rowcounts
                }
                
        }
        
        masterPredictions$currmean <- (masterPredictions$SummedPreds / masterPredictions$count)
        return(masterPredictions)
}


GroupFactorsTogether <- function(objData, 
                                 variableName, 
                                 clustersize=200, 
                                 dropVarCol=FALSE, 
                                 plotIt=FALSE,
                                 LearnMode = FALSE,
                                 method='jw') {
        #      stringdistmatrix(a, b, method = c("osa", "lv", "dl", "hamming", "lcs",
        #                                        "qgram", "cosine", "jaccard", "jw", "soundex"), useBytes = FALSE,
        #                       weight = c(d = 1, i = 1, s = 1, t = 1), maxDist = Inf, q = 1, p = 0,
        #                       useNames = FALSE, ncores = 1, cluster = NULL)
        
        #      http://cran.r-project.org/web/packages/stringdist/stringdist.pdf     
        #      osa Optimal string aligment, (restricted Damerau-Levenshtein distance).
        #      lv Levenshtein distance (as in R's native adist).
        #      dl Full Damerau-Levenshtein distance.
        #      hamming Hamming distance (a and b must have same nr of characters).
        #      lcs Longest common substring distance.
        #      qgram q-gram distance.
        #      cosine cosine distance between q-gram profiles
        #      jaccard Jaccard distance between q-gram profiles
        #      jw Jaro, or Jaro-Winker distance.
        #      soundex Distance based on soundex encoding
        
        library(stringdist)
        maxUniques <-length(unique(objData[,variableName]))
        if (maxUniques < clustersize)
                clustersize <- maxUniques
        
        str <- unique(as.character(objData[,variableName]))
        print(paste('Uniques:',length(str)))
        # d  <- adist(str)
        # d  <- amatch(str,maxdist=5)
        
        d <- stringdistmatrix(str,str,method = c(method))
        
        rownames(d) <- str
        hc <- hclust(as.dist(d))
        if (plotIt) {
                plot(hc)
                rect.hclust(hc,k=clustersize)
                
        }
        
        dfClust <- data.frame(str, cutree(hc, k=clustersize))
        #plot(table(dfClust$'cutree.hc..k...k.'))
        
        if (LearnMode) {
                most_populated_clusters <- dfClust[dfClust$'cutree.hc..k...k.' > 5,]
                names(most_populated_clusters) <- c('entry','cluster')
                
                # sort by most frequent
                t <- table(most_populated_clusters$cluster)
                t <- cbind(t,t/length(most_populated_clusters$cluster))
                t <- t[order(t[,2], decreasing=TRUE),]
                p <- data.frame(factorName=rownames(t), binCount=t[,1], percentFound=t[,2])
                most_populated_clusters <- merge(x=most_populated_clusters, y=p, by.x = 'cluster', by.y='factorName', all.x=T)
                most_populated_clusters <- most_populated_clusters[rev(order(most_populated_clusters$binCount)),]
                names(most_populated_clusters) <-  c('cluster','entry')
                return (most_populated_clusters[c('cluster','entry')])
        }
        
        # merge results back to original data frame
        # "str"               "cutree.hc..k...k."
        objData <- merge(x=objData, y=dfClust, all.x=TRUE, by.x=variableName, by.y="str")
        
        # drop original 
        if (dropVarCol) {
                objData <- objData[,!(names(objData) %in% c(variableName))]
                # rename new field
                names(objData)[ncol(objData)] <- variableName 
        }
        return(objData)
}

clusterTextColumns <- function(objDF, varName, clustSize) {
        
        cutoff <- 1
        
        # use first word of final drg
        # objDF[,varName] <- sapply(strsplit(as.character(objDF[,varName])," "),"[",1)
        
        t <- table(objDF[,varName])
        t <-cbind(t,t/length(objDF[,varName]))
        t <- t[order(t[,2], decreasing=TRUE),]
        p <- data.frame(factorName=rownames(t), binCount=t[,1], percentFound=t[,2])
        # remove all those with 1 occurence only
        p <- p[p$binCount > cutoff,]
        
        # only keep columns wanted and replace all others with 'other'
        keeperVars <- rownames(p)
        
        objDF[,varName] <- as.character(objDF[,varName])
        objDF[,varName] <- ifelse(objDF[,varName] %in% keeperVars, objDF[,varName], 'other')
        
        objDF <- GroupFactorsTogether(objDF, varName, clustersize=clustSize, plotIt=F,method='jw', dropVarCol=T)
        objDF[,varName] <- as.factor(objDF[,varName])
        return (objDF)
}


DistanceBetweenTwoGeopoints <- function(lat1, lon1, lat2, lon2) {
        #gdist(lon.1, lat.1, lon.2, lat.2, units = "nm", a = 6378137.0, b = 6356752.3142, verbose = FALSE)
        if (suppressWarnings(!is.na(as.numeric(lat1)))==T  
            & suppressWarnings(!is.na(as.numeric(lon1)))==T
            & suppressWarnings(!is.na(as.numeric(lat2)))==T
            & suppressWarnings(!is.na(as.numeric(lon2)))==T) {
                
                return(gdist(lon1, lat1, lon2, lat2, units='miles'))
        } else {
                return (NA)
        }
}

swapWithLevenshteinDistance <- function(objData, 
                                        variableName, 
                                        kClustSize, 
                                        getAdviceOnly=F,
                                        dropVarCol=F, 
                                        plotIt=F,
                                        method='jw') {
        #      stringdistmatrix(a, b, method = c("osa", "lv", "dl", "hamming", "lcs",
        #                                        "qgram", "cosine", "jaccard", "jw", "soundex"), useBytes = FALSE,
        #                       weight = c(d = 1, i = 1, s = 1, t = 1), maxDist = Inf, q = 1, p = 0,
        #                       useNames = FALSE, ncores = 1, cluster = NULL)
        
        #      http://cran.r-project.org/web/packages/stringdist/stringdist.pdf     
        #      osa Optimal string aligment, (restricted Damerau-Levenshtein distance).
        #      lv Levenshtein distance (as in R's native adist).
        #      dl Full Damerau-Levenshtein distance.
        #      hamming Hamming distance (a and b must have same nr of characters).
        #      lcs Longest common substring distance.
        #      qgram q-gram distance.
        #      cosine cosine distance between q-gram profiles
        #      jaccard Jaccard distance between q-gram profiles
        #      jw Jaro, or Jaro-Winker distance.
        #      soundex Distance based on soundex encoding
        
        library(stringdist)
        maxUniques <-length(unique(objData[,variableName]))
        if (maxUniques < kClustSize)
                kClustSize <- maxUniques
        
        str <- unique(as.character(objData[,variableName]))
        print(paste('Uniques:',length(str)))
        # d  <- adist(str)
        # d  <- amatch(str,maxdist=5)
        
        d <- stringdistmatrix(str,str,method = c(method))
        
        rownames(d) <- str
        hc <- hclust(as.dist(d))
        k=kClustSize
        if (plotIt) {
                plot(hc)
                rect.hclust(hc,k=k)
        }
        
        dfClust <- data.frame(str, cutree(hc, k=k))
        
        # merge results back to original data frame
        # "str"               "cutree.hc..k...k."
        objData <- merge(x=objData, y=dfClust, all.x=TRUE, by.x=variableName, by.y="str")
        
        # drop original 
        if (dropVarCol) {
                objData <- objData[,!(names(objData) %in% c(variableName))]
                # rename new field
                names(objData)[ncol(objData)] <- variableName 
        }
        return(objData)
}


clusterTextColumns <- function(objDF, varName, clustSize) {
        
        cutoff <- 1
        
        # use first word of final drg
        # objDF[,varName] <- sapply(strsplit(as.character(objDF[,varName])," "),"[",1)
        
        t <- table(objDF[,varName])
        t <-cbind(t,t/length(objDF[,varName]))
        t <- t[order(t[,2], decreasing=TRUE),]
        p <- data.frame(factorName=rownames(t), binCount=t[,1], percentFound=t[,2])
        # remove all those with 1 occurence only
        p <- p[p$binCount > cutoff,]
        
        # only keep columns wanted and replace all others with 'other'
        keeperVars <- rownames(p)
        
        objDF[,varName] <- as.character(objDF[,varName])
        objDF[,varName] <- ifelse(objDF[,varName] %in% keeperVars, objDF[,varName], 'other')
        
        objDF <- swapWithLevenshteinDistance(objDF, varName, kClustSize=clustSize, plotIt=F,method='jw', dropVarCol=T)
        objDF[,varName] <- as.factor(objDF[,varName])
        return (objDF)
}


FlowsheetTimeSeriesAggregator <- function(PathAndFileName) {
        print(paste('Reading...', PathAndFileName))
        flowdata <- read.csv(PathAndFileName)
        flowdata$PAT_ENC_CSN_ID <- as.character(flowdata$PAT_ENC_CSN_ID)
        flowsheetName <- gsub(x = as.character(flowdata$FLOWSHEET[1]),pattern = " ",replacement = "_")
        flowdata <- flowdata[c('PAT_ENC_CSN_ID','RECORDED_TIME','MEAS_VALUE')]
        flowdata$RECORDED_TIME <- as.character(flowdata$RECORDED_TIME)
        encounters <- unique(flowdata$PAT_ENC_CSN_ID)
        
        # date sub set
        flowdata_bydate <- flowdata
        flowdata_bydate <- flowdata_bydate[c('PAT_ENC_CSN_ID','MEAS_VALUE')]
        print('Calculating min')
        minvalues <- aggregate(.~PAT_ENC_CSN_ID,data=flowdata_bydate, FUN=min)
        names(minvalues) <- c('PAT_ENC_CSN_ID', paste0(flowsheetName,"_Min"))
        
        print('Calculating max')
        maxvalues <- aggregate(.~PAT_ENC_CSN_ID,data=flowdata_bydate, FUN=max)
        names(maxvalues) <- c('PAT_ENC_CSN_ID', paste0(flowsheetName,"_Max"))
        
        print('Calculating mean')
        meanvalues <- aggregate(.~PAT_ENC_CSN_ID,data=flowdata_bydate, FUN=mean)
        names(meanvalues) <- c('PAT_ENC_CSN_ID', paste0(flowsheetName,"_Mean"))
        
        print('Calculating median')
        medianvalues <- aggregate(.~PAT_ENC_CSN_ID,data=flowdata_bydate, FUN=median)
        names(medianvalues) <- c('PAT_ENC_CSN_ID', paste0(flowsheetName,"_Median"))
        
        
        # time subset
        flowdata_bytime <- flowdata
        flowdata_bytime$RECORDED_TIME <- as.POSIXct(strptime(flowdata_bytime$RECORDED_TIME, "%Y-%m-%d %H:%M:%S"))
        flowdata_bytime <- flowdata_bytime[order(flowdata_bytime$PAT_ENC_CSN_ID, flowdata_bytime$RECORDED_TIME,decreasing = FALSE),]
        
        print('Retrieving first')
        firstvalues <- flowdata_bytime[which(!duplicated(flowdata_bytime$PAT_ENC_CSN_ID)),]
        firstvalues <- firstvalues[c('PAT_ENC_CSN_ID','MEAS_VALUE')]
        names(firstvalues) <- c('PAT_ENC_CSN_ID',paste0(flowsheetName,"_First"))
        
        print('Retrieving last')
        flowdata_bytime <- flowdata_bytime[order(flowdata_bytime$PAT_ENC_CSN_ID, flowdata_bytime$RECORDED_TIME,decreasing = TRUE),]
        lastvalues <- flowdata_bytime[which(!duplicated(flowdata_bytime$PAT_ENC_CSN_ID)),]
        lastvalues <- lastvalues[c('PAT_ENC_CSN_ID','MEAS_VALUE')]
        names(lastvalues) <- c('PAT_ENC_CSN_ID',paste0(flowsheetName,"_Last"))
        
        newData <- data.frame('PAT_ENC_CSN_ID'=encounters)
        newData <- merge(x=newData, y=minvalues, by='PAT_ENC_CSN_ID', all.x=TRUE)
        newData <- merge(x=newData, y=maxvalues, by='PAT_ENC_CSN_ID', all.x=TRUE)
        newData <- merge(x=newData, y=meanvalues, by='PAT_ENC_CSN_ID', all.x=TRUE)
        newData <- merge(x=newData, y=medianvalues, by='PAT_ENC_CSN_ID', all.x=TRUE)
        newData <- merge(x=newData, y=firstvalues, by='PAT_ENC_CSN_ID', all.x=TRUE)
        newData <- merge(x=newData, y=lastvalues, by='PAT_ENC_CSN_ID', all.x=TRUE)
        
        return(newData)
}


TrackAllImputation <- function(objDF) {
        for (v in names(objDF)){
                if (any(is.na(objDF[,v]))) {
                        # create binary column before imputing with mean
                        newName <- paste0(v,'_NA')
                        objDF[,newName] <- as.integer(ifelse(is.na(objDF[,v]),1,0)) }
                
                if (any(is.infinite(objDF[,v]))) {
                        newName <- paste0(v,'_inf')
                        objDF[,newName] <- as.integer(ifelse(is.infinite(objDF[,v]),1,0)) }
                
                if (any(is.nan(objDF[,v]))) {
                        newName <- paste0(v,'_NaN')
                        objDF[,newName] <- as.integer(ifelse(is.nan(objDF[,v]),1,0)) }
        }
        return (objDF)
}


replaceAllNAsWithNumber <- function(objDF,num) {
        objDF[is.na(objDF)] <- num
        return(objDF)
}
 
# data --------------------------------------------------------------------
 
temp <- tempfile()

download.file('http://archive.ics.uci.edu/ml/machine-learning-databases/kddcup99-mld/kddcup.data_10_percent.gz',temp)
basedf <- read.csv(temp,header=FALSE)
basedf <- basedf[sample()]
# http://archive.ics.uci.edu/ml/machine-learning-databases/kddcup99-mld/

varnames <- c("duration", "protocol_type", "service", "flag", "src_bytes",
              "dst_bytes", "land", "wrong_fragment", "urgent", "hot", 
              "num_failed_logins", "logged_in", "num_compromised", "root_shell", 
              "su_attempted", "num_root", "num_file_creations", "num_shells", 
              "num_access_files", "num_outbound_cmds", "is_host_login", 
              "is_guest_login", "count", "srv_count", "serror_rate", "srv_serror_rate", 
              "rerror_rate", "srv_rerror_rate", "same_srv_rate", "diff_srv_rate", 
              "srv_diff_host_rate", "dst_host_count", "dst_host_srv_count", 
              "dst_host_same_srv_rate", "dst_host_diff_srv_rate", "dst_host_same_src_port_rate", 
              "dst_host_srv_diff_host_rate", "dst_host_serror_rate", "dst_host_srv_serror_rate", 
              "dst_host_rerror_rate", "dst_host_srv_rerror_rate", "label")

names(basedf) <- varnames

dim(basedf)
prop.table(table(basedf$label))


charcolumns <- names(basedf[sapply(basedf, is.factor)])
for (thecol in charcolumns) {
        print(paste(thecol,length(unique(basedf[,thecol]))))
}

charcolumns <- names(basedf[sapply(basedf, is.character)])
for (thecol in charcolumns) {
        print(paste(thecol,length(unique(basedf[,thecol]))))
}

outcomeName <- 'label'
basedf$label <- ifelse(basedf$label=='normal.',1,0)

require(caret)
dmy <- dummyVars(" ~ .", data = basedf)
basedf<- data.frame(predict(dmy, newdata = basedf))

# factorize the label only after dummyVars call
basedf$label <- ifelse(basedf$label==1,'normal','attack')
basedf$label <- as.factor(basedf$label)

basedf <- basedf[sample(nrow(basedf), floor(0.2*nrow(basedf))),]

dim(basedf)
# 494021    119
# remove low variance 
require(caret)
nzv <- nearZeroVar(basedf, saveMetrics = TRUE)
print(paste('Range:',range(nzv$percentUnique)))
# "Range: 0.000202420544875623" "Range: 2.17096034379105" 
# zerovarcutoff <- 0.02
# dim(basedf)
# basedf <- basedf[c(rownames(nzv[nzv$percentUnique > zerovarcutoff,])) ]
# dim(basedf)
 

# model -------------------------------------------------------------------

set.seed(1234)
split <- sample(nrow(basedf), floor(0.7*nrow(basedf)))
traindf <-basedf[split,]
testdf <- basedf[-split,]

predictorsNames <- names(basedf)[!names(basedf) %in% outcomeName]

require(caret)
objControl <- trainControl(method='none', classProbs = TRUE)
objModel <- train(traindf[,predictorsNames], traindf[,outcomeName], 
                  method='gbm', 
                  trControl=objControl,  
                  metric = "ROC",
                  tuneGrid = expand.grid(n.trees = 10, interaction.depth = 2, shrinkage = 0.1),
                  preProc = c("center", "scale"))
library(pROC)
predictions <- predict(object=objModel, testdf[,predictorsNames], type='prob')
head(predictions)
auc <- roc(ifelse(testdf[,outcomeName]=="normal",1,0), predictions[[2]])
print(auc$auc)

# bagged version


# Area under the curve: 0.9991


# parallel   ---------------------------------------------------------
library(foreach)
library(doParallel)

#setup parallel backend to use 8 processors
cl<-makeCluster(7)
registerDoParallel(cl)


objControl <- trainControl(method='none', classProbs = TRUE)

set.seed(1234)
split <- sample(nrow(basedf), floor(0.7*nrow(basedf)))
traindf <- basedf[split,]
testdf <-  basedf[-split,]
predictorsNames <- names(epadata)[!names(epadata) %in% outcomeName]


length_divisor <-20
predictions<-foreach(m=1:50,.combine=cbind) %dopar% { 
        require(caret)
        
        training_positions <- sample(nrow(traindf), size=floor((nrow(traindf)/length_divisor))) 
        train_pos<-1:nrow(traindf) %in% training_positions
        
        objControl <- trainControl(method='none', classProbs = TRUE)
        objModel <- train(traindf[train_pos,][,predictorsNames], traindf[train_pos,][,outcomeName],
                          method='gbm',
                          trControl=objControl, 
                          metric = "ROC",
                          tuneGrid = expand.grid(n.trees = 10, interaction.depth = 2, shrinkage = 0.1),
                          preProc = c("center", "scale"))
        
        predictions <- predict(object=objModel, testdf[,predictorsNames])
} 
stopCluster(cl)
# Area under the curve: 0.9873



library(pROC)
 
auc <- roc(ifelse(testdf[,outcomeName]=="normal",1,0), rowMeans(predictions))
print(auc$auc)
Area under the curve: 0.999



