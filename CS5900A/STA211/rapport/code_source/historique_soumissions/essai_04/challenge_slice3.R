library(ggplot2)
library(dplyr)
library(caret)
library(lattice)
library(stringr)


training <- readRDS(file="training.rds")

load("data_test.rda")

drop.cols <- colnames(data_test)[ apply(data_test, 2, anyNA) ]
testing <-  data_test %>% select(-one_of(drop.cols))


control <- trainControl(method="cv", number=5,search="grid")
metric <- "Accuracy"

seed <- 7
set.seed(seed)


Sys.time()


tunegrid <- expand.grid(.mtry=c(30))
rf_random <- train(outcome~., data=training, method="rf", metric=metric, tuneGrid=tunegrid, trControl=control)

modelFile <- paste("model","all",".rds",sep=".")    
saveRDS(rf_random,file=modelFile)


predictions <-predict.train(object=rf_random,testing)
fichier <- paste("predictions","all","csv",sep=".")
print(paste(Sys.time(),fichier))
    
write.csv(predictions,fichier ,row.names = FALSE)


Sys.time()


