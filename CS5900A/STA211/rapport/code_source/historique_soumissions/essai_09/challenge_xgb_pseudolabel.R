library(ggplot2)
library(dplyr)
library(caret)
library(lattice)
library(stringr)
library(xgboost)
library(Matrix)
library(data.table)
library(missMDA)


load("data_train.rda")
load("data_test.rda")

colnames(data_train) <- make.names(names(data_train))
colnames(data_test) <- make.names(names(data_test))



not.in.univ_yes_no <- c("Not in universe","Yes","No")

industry_levels <- c("Not in universe", "Agriculture Service", "Other Agriculture", "Mining",
                     "Construction","Lumber and wood products, except furniture","Furniture and fixtures",
                     "Stone clay, glass, and concrete product", "Primary metals", "Fabricated metal", 
                     "Not specified metal industries", "Machinery, except electrical", 
                     "Electrical machinery,equipment, and supplies", "Motor vehicles and equipment",
                     "Aircraft and pans", "Other transportation equipment", 
                     "Professional and photographic equipment, and watches",
                     "Toys, amusements, and sporting goods", 
                     "Miscellaneous and not specified manufacturing industries", 
                     "Food and kindred products", "Tobacco manufactures", "Textile mill products",
                     "Apparel and other finished textile products", "Paper and allied products", 
                     "Printing, publishing and allied industries", "Chemicals and allied products", 
                     "Petroleum and coal products", "Rubber and miscellaneous plastics products", 
                     "Leather and leather products","Transportation", "Communications", 
                     "Utilities and Sanitary Services", "Wholesale Trade",
                     "Retail Trade", "Banking and Other Finance", "Insurance and Real Estate", 
                     "Private Household Services", "Business Services", "Repair Services", 
                     "Personal Services, Except Private Household", 
                     "Entertainment and Recreation Services","Hospitals", 
                     "Health Services, Except Hospitals", "Educational Services", "Social Services", 
                     "Other Professional Services", "Forestry and Fisheries", "Justice, Public Order and Safety",
                     "Administration of Human Resource Programs", "National Security and Internal Affairs", 
                     "Other Public Administration","Armed Forces last job, currently unemployed")

occupation_levels <- c("Not in universe",  "Public Administration", "Other Executive,
                       Administrators, and Managers", "Management Related Occupations", "Engineers",
                       "Mathematical and Computer Scientists", "Natural Scientists","Health Diagnosing Occupations",
                       "Health Assessment and Treating Occupations", "Teachers, College and University", 
                       "Teachers, Except College and University", "Lawyers and Judges", 
                       "Other Professional Specialty Occupations", "Health Technologists and Technicians",
                       "Engineering and Science Technicians", "Technicians, Except Health Engineering. and Science",
                       "Supervisors and Proprietors, Sales Occupations", 
                       "Sales Representatives, Finance, and Business Service",
                       "Sales Representatives, Commodities, Except Retail", 
                       "Sales Workers, Retail and Personal Services", "Sales Related Occupations", 
                       "Supervisors - Administrative Support", "Computer Equipment Operators", 
                       "Secretaries, Stenographers, and Typists","Financial Records, Processing Occupations", 
                       "Mail and Message Distributing","Other Administrative Support Occupations, Including Clerical",
                       "Private Household Service Occupations","Protective Service Occupations", 
                       "Food Service Occupations", "Health Service Occupations", 
                       "Cleaning and Building Service Occupations",  "Personal Service Occupations",
                       "Mechanics and Repairers","Construction Trades",
                       "Other Precision Production Occupations", 
                       "Machine Operators and Tenders, Except Precision", 
                       "Fabricators, Assemblers, Inspectors, and Samplers", "Motor Vehicle Operators", 
                       "Other Transportation Occupations and Material Moving","Construction Laborer",
                       "Freight, Stock and Material Handlers","Other Handlers, Equipment Cleaners. and Laborers", 
                       "Farm Operators and Managers","Farm Workers and Related Occupations",
                       "Forestry and Fishing Occupations", "Armed Forces last job, currently unemployed") 

data_train$detailed.industry.recode. <- as.factor(data_train$detailed.industry.recode.)
levels(data_train$detailed.industry.recode.) <- industry_levels
data_train$detailed.occupation.recode <- as.factor(data_train$detailed.occupation.recode)
levels(data_train$detailed.occupation.recode) <- occupation_levels
data_train$business.or.self.employed <- as.factor(data_train$business.or.self.employed)
levels(data_train$ business.or.self.employed) <- not.in.univ_yes_no
data_train$veterans.benefits <-  as.factor(data_train$veterans.benefits)
levels(data_train$veterans.benefits) <- not.in.univ_yes_no
data_train$year <- as.factor(data_train$year)

data_test$detailed.industry.recode. <- as.factor(data_test$detailed.industry.recode.)
levels(data_test$detailed.industry.recode.) <- industry_levels
data_test$detailed.occupation.recode <- as.factor(data_test$detailed.occupation.recode)
levels(data_test$detailed.occupation.recode) <- occupation_levels
data_test$business.or.self.employed <- as.factor(data_test$business.or.self.employed)
levels(data_test$ business.or.self.employed) <- not.in.univ_yes_no
data_test$veterans.benefits <-  as.factor(data_test$veterans.benefits)
levels(data_test$veterans.benefits) <- not.in.univ_yes_no
data_test$year <- as.factor(data_test$year)

int_cols <- which(sapply(data_train, class)=="integer")
for(i in int_cols){
    data_train[,i] <- as.numeric(data_train[,i])
    data_test[,i] <- as.numeric(data_test[,i])
}


var.factor<-which(sapply(data_train,class)=="factor")
var.num <- which(sapply(data_train,class)=="numeric")

drop.cols <- colnames(data_train)[ apply(data_train, 2, anyNA) ]
training <-  data_train %>% select(-one_of(drop.cols))
testing <-  data_test %>% select(-one_of(drop.cols))


pseudo_labels <- read.csv(file="pseudo_labels.csv", header=TRUE, sep=",",colClasses = c("factor"))
training_ext <- testing
training_ext$outcome <- pseudo_labels$outcome
training <-rbind(training,training_ext)


training <- data.table(training) 
testing <- data.table(testing)



dtrain <- sparse.model.matrix(outcome~.-1, data = training)
dlabel <- as.numeric(training$outcome)-1

testing$outcome=0
dtest <- sparse.model.matrix(outcome~.-1, data = testing)

colsamples_bytree <- c(0.475,0.5,0.525)
max_depths <- 6:8
min_child_weights <- 1:3


colsamples_bytree <- c(0.5)
max_depths <- c(8)
min_child_weights <- c(1)


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
                write.csv(best_params,"best_params_preprocess.csv")
                # Pass in our hyperparameteres and train the model 
                system.time(xgbmodel <- xgboost(params  = param,
                                           data    = dtrain,
                                           label   = dlabel,
                                           nthread = 2,
                                           nrounds = xgbcv$best_iteration,
                                           print_every_n = 100,
                                           verbose = 1))
                xgb.save(xgbmodel, "best_xgb_model")
                
                predictions <- predict(xgbmodel, dtest)
                predictions[predictions<0.5]=0
                predictions[predictions>=0.5]=1
                predictions[predictions==0]="-50000"
                predictions[predictions==1]="+50000"
                write.csv(predictions,"predictions.csv" ,row.names = FALSE)
            }
           
                    
            i <- i+1
        }
    }
}
print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
print(best_params)
print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")


model=xgb.load("best_xgb_model")
importance_matrix <- xgb.importance(colnames(dtrain), model = model)
xgb.plot.importance(importance_matrix, rel_to_first = TRUE, xlab = "Relative importance")
(gg <- xgb.ggplot.importance(importance_matrix, measure = "Frequency", rel_to_first = TRUE,top_n = 30))
gg + ggplot2::ylab("Frequency")


Sys.time()


