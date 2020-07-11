library(ggplot2)
library(dplyr)
library(caret)
library(lattice)
library(stringr)
library(Matrix)
library(data.table)
library(forcats)
library(plyr)
library(xgboost)

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

occupation_levels <- c("Not in universe",  "Public Administration", 
                       "Other Executive, Administrators, and Managers", "Management Related Occupations", "Engineers",
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

vars_country_state <- c("country.of.birth.father","country.of.birth.mother","country.of.birth.self","state.of.previous.residence")

for(v in vars_country_state )
{    
    data_train[,v]<-fct_explicit_na(data_train[,v])
    data_test[,v]<-fct_explicit_na(data_test[,v])
}


# on supprime les colonnes "migrations..." qui comportent 50 % de données manquantes
drop.cols <- c("migration.code.change.in.msa",           
               "migration.code.change.in.reg",           
               "migration.code.move.within.reg",        
               "migration.prev.res.in.sunbelt")

training <-  data_train %>% select(-one_of(drop.cols))
testing <-  data_test %>% select(-one_of(drop.cols))

training <- data.table(training) 
testing <- data.table(testing)


dtrain <- xgb.DMatrix(data = sparse.model.matrix(outcome~.-1, data = training),
                      label=as.numeric(training$outcome)-1)



testing$outcome=0
dtest <- sparse.model.matrix(outcome~.-1, data = testing)


colsamples_bytree <- seq(from=0.35,to=1,by=0.025)
max_depths <- 6:7
min_child_weights <- c(1)

params_history <- data.frame(
    colsample_bytree=numeric(),
    max_depth=integer(),
    min_child_weight=integer(),
    error=numeric()
)


best_params <- c()
best_params$colsample_bytree <- 1
best_params$max_depth <- 1
best_params$min_child_weight <- 1
best_params$error <- 1




preds_ensemble <- c();

nb_predictors <- length(colsamples_bytree) * length(max_depths) * length(min_child_weights)

pred_stack <- as.data.frame(matrix(NA, nrow=nrow(testing), ncol=nb_predictors))

for(j in 1:nb_predictors){
    pred_stack[,j] <- as.numeric(pred_stack[,j])
}


Sys.time()
i<-1
for(colsample_bytree in colsamples_bytree)
{
    for (max_depth in max_depths){
        for (min_child_weight in min_child_weights){
            
            
            param <- list(objective   = "binary:logistic",
                          eval_metric = "error",
                          colsample_bytree = colsample_bytree,
                          max_depth   = max_depth,
                          eta         = 0.1,
                          min_child_weight = min_child_weight)
            
            
            set.seed(1234)
            
            print(paste("==> <",i,">, ", Sys.time(),", colsample_bytree : ",colsample_bytree,", max_depth : ",max_depth,", min_child_weight : ",min_child_weight,sep=""))
            
            
            xgbcv <- xgb.cv(params = param
                            ,data = dtrain
                            ,nrounds = 800
                            ,nfold = 10
                            ,showsd = T
                            ,stratified = T
                            ,print_every_n  = 10
                            ,early_stopping_rounds = 50
                            ,maximize = F
            )
            
    
            xgbmodel <- xgboost(params  = param,
                                data    = dtrain,
                                nthread = 2,
                                nrounds = xgbcv$best_iteration,
                                print_every_n = 100,
                                verbose = 1)
                    
            error <- xgbcv$evaluation_log$test_error_mean[xgbcv$best_iteration]
            
            iter_params <- c()
            iter_params$max_depth <- max_depth
            iter_params$colsample_bytree <- colsample_bytree
            iter_params$min_child_weight <- min_child_weight
            iter_params$best_iteration <- xgbcv$best_iteration
            iter_params$error <- error
            
            params_history <- rbind(params_history,iter_params )
            write.csv(params_history,"params_history.csv" ,row.names = FALSE)
            
            pred_stack[,i] <- predict(xgbmodel, dtest)
            
            if(error < best_params$error){
                best_params <- iter_params
                print(best_params)
                write.csv(best_params,"best_params.csv")
                # Pass in our hyperparameteres and train the model 
                xgb.save(xgbmodel, "best_xgb_model")
                
                predictions <- predict(xgbmodel, dtest)
                predictions[predictions<0.5]=-1
                predictions[predictions>=0.5]=1
                predictions[predictions==-1]="-50000"
                predictions[predictions==1]="+50000"
                write.csv(predictions,"predictions.csv" ,row.names = FALSE)
                
            } 
            i <- i+1
        }
    }
}


print("!!!!!!!!!!!!!!!!!!")
print(best_params)
print("!!!!!!!!!!!!!!!!!!")

print("!!!!!!!!!!!!!!!!!!")

save(pred_stack,file="pred_stack.rda")


Sys.time()

preds <-rowMeans(pred_stack)
preds[preds<0.5]=-1
preds[preds>=0.5]=1
preds[preds<0]="-50000"
preds[preds>0]="+50000"


write.csv(preds,"predictions_mean.csv" ,row.names = FALSE)

model=xgb.load("best_xgb_model")

importance_matrix <- xgb.importance(colnames(dtrain), model = model)
xgb.plot.importance(importance_matrix, rel_to_first = TRUE, xlab = "Relative importance")
(gg <- xgb.ggplot.importance(importance_matrix, measure = "Frequency", rel_to_first = TRUE,top_n = 30))
gg + ggplot2::ylab("Frequency")


df_importance <-  data.frame(importance_matrix$Feature,importance_matrix$Importance) 
df_importance <- df_importance[with(df_importance, order(-importance_matrix.Importance)), ] 
df_importance$rank <- 1:nrow(df_importance)

write.csv(df_importance,"df_importance.csv" ,row.names = FALSE)

matrix =sparse.model.matrix(outcome~.-1, data = training)
training2 = as.data.frame(as.matrix(matrix))
training2  <- training2 %>%  select(df_importance$importance_matrix.Feature[1:236])

