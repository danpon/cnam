library(ggplot2)
library(dplyr)
library(caret)


randomSample = function(df,n) { 
    return (df[sample(nrow(df), n),])
}

load("data_train.rda")
load("data_test.rda")

drop.cols <- colnames(data_train)[ apply(data_train, 2, anyNA) ]




training <-  data_train %>% select(-one_of(drop.cols))
testing <-  data_test %>% select(-one_of(drop.cols))

set.seed(5)

training <- randomSample(training,20000)

#training[sample.int(nrow(training)),]



control <- trainControl(method="cv", number=5,search="random")
metric <- "Accuracy"

seed <- 7
set.seed(seed)


Sys.time()

rf_random <- train(outcome~., data=training, method="rf", metric=metric, tuneLength=10, trControl=control)
#print(rf_random)
#plot(rf_random)


predictions<-predict.train(object=rf_random,testing)

Sys.time()
write.csv(predictions, "predictions.csv",row.names = FALSE)

