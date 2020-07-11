

load("data_train.rda")

drop.cols <- colnames(data_train)[ apply(data_train, 2, anyNA) ]

training <-  data_train %>% select(-one_of(drop.cols))

set.seed(5)


training <- training[sample.int(nrow(training)),]

saveRDS(training, file="training.rds")

#28503