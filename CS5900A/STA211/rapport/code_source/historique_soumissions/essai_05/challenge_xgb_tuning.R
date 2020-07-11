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

# Set our hyperparameters
param <- list(objective   = "binary:logistic",
              eval_metric = "error",
              max_depth   = 7,
              eta         = 0.1,
              gammma      = 1,
              colsample_bytree = 0.7,
              min_child_weight = 1)

set.seed(1234)

xgbcv <- xgb.cv(params = param
                ,data = dtrain
                ,label = dlabel
                ,nrounds = 800
                ,nfold = 5
                ,showsd = T
                ,stratified = T
                ,print.every.n = 10
                ,early.stop.round = 80
                ,maximize = F
)


# Pass in our hyperparameteres and train the model 
system.time(xgb <- xgboost(params  = param,
                           data    = dtrain,
                           label   = dlabel,
                           nthread = 2,
                           nrounds = 359,
                           print_every_n = 100,
                           verbose = 1))

predictions <- predict(xgb, dtest)
predictions[predictions<0.5]=0
predictions[predictions>=0.5]=1
predictions[predictions==0]="-50000"
predictions[predictions==1]="+50000"
predictions
write.csv(predictions,"predictions_xgb2.csv" ,row.names = FALSE)


Sys.time()


