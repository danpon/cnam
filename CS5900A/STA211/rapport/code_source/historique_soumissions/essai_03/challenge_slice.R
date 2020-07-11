library(ggplot2)
library(dplyr)
library(caret)
library(lattice)
library(stringr)


training <- readRDS(file="training.rds")

load("data_test.rda")

drop.cols <- colnames(data_test)[ apply(data_test, 2, anyNA) ]
testing <-  data_test %>% select(-one_of(drop.cols))


control <- trainControl(method="cv", number=5,search="random")
metric <- "Accuracy"

seed <- 7
set.seed(seed)

step <- 28503

indice_slice <- 1
nb_slices <- 7


row_start <- (indice_slice-1)* step + indice_slice
row_end <- row_start + step

row_start
row_end


Sys.time()


training_slice <- training[row_start:row_end,]

rf_random <- train(outcome~., data=training_slice, method="rf", metric=metric, tuneLength=10, trControl=control)
predictions <-predict.train(object=rf_random,testing)

    
fichier <- paste("predictions",indice_slice,"csv",sep=".")
print(paste(Sys.time(),fichier))
    
write.csv(predictions,fichier ,row.names = FALSE)
    

Sys.time()


