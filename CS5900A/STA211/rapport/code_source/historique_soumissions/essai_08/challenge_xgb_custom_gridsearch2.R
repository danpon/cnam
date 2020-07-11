library(ggplot2)
library(dplyr)
library(caret)
library(lattice)
library(stringr)
library(xgboost)
library(Matrix)
library(data.table)


training <- readRDS(file="training.rds")

load("data_test.rda")

drop.cols <- colnames(data_test)[ apply(data_test, 2, anyNA) ]
testing <-  data_test %>% select(-one_of(drop.cols))


training <- data.table(training) 
colnames(training) <- make.names(names(training))

testing <- data.table(testing)
colnames(testing) <- make.names(names(testing))

dtrain <- sparse.model.matrix(outcome~.-1, data = training)
dlabel <- as.numeric(training$outcome)-1

testing$outcome=0
dtest <- sparse.model.matrix(outcome~.-1, data = testing)

colsamples_bytree <- c(0.475,0.5,0.525)
max_depths <- 6:8
min_child_weights <- 1:3

best_params <- c()
best_params$colsample_bytree <- 1
best_params$best_iteration <- 1
best_params$max_depth <- 0
best_params$min_child_weight <- 0
best_params$error <- 1


Sys.time()
i<-1


preds_ensemble <- c();

for(colsample_bytree in colsamples_bytree)
{
    for (max_depth in max_depths){
        for (min_child_weight in min_child_weights){
            param <- list(objective   = "binary:logistic",
                          eval_metric = "error",
                          colsample_bytree = colsample_bytree,
                          max_depth   = max_depth,
                          eta         = 0.1,
                          gammma      = 1,
                          min_child_weight = min_child_weight)
            
            
            set.seed(1234)
            
            print(paste("==> <",i,">, ", Sys.time(),", colsample_bytree : ",colsample_bytree,", max_depth : ",max_depth,", min_child_weight : ",min_child_weight,sep=""))
            
            
            xgbcv <- xgb.cv(params = param
                            ,data = dtrain
                            ,label = dlabel
                            ,nrounds = 800
                            ,nfold = 10
                            ,showsd = T
                            ,stratified = T
                            ,print.every.n = 10
                            ,early.stop.round = 50
                            ,maximize = F
            )
            
            
            error <- xgbcv$evaluation_log$test_error_mean[xgbcv$best_iteration]
            if(error< best_params$error){
                best_params$max_depth <- max_depth
                best_params$colsample_bytree <- colsample_bytree
                best_params$min_child_weight <- min_child_weight
                best_params$best_iteration <- xgbcv$best_iteration
                best_params$error <- error
                print(best_params)
                write.csv(best_params,"best_params.csv")
            }
            # Pass in our hyperparameteres and train the model 
            system.time(xgb <- xgboost(params  = param,
                                       data    = dtrain,
                                       label   = dlabel,
                                       nthread = 2,
                                       nrounds = xgbcv$best_iteration,
                                       print_every_n = 100,
                                       verbose = 1))
                
            preds <- predict(xgb, dtest)
            preds[preds<0.5]=-1
            preds[preds>=0.5]=1
            
            preds_ensemble <- cbind(preds_ensemble,preds)
                
            i <- i+1
        }
    }
}
print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
print(best_params)
print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")

predictions <- rowSums(preds_ensemble)
write.csv(predictions,"temp.csv");


predictions[predictions<0]="-50000"
predictions[predictions>0]="+50000"
predictions
write.csv(predictions,"predictions_xgb_ensembles.csv" ,row.names = FALSE)


Sys.time()


