library(ggplot2)
library(plyr)
library(dplyr)
library(caret)
library(lattice)
library(stringr)
library(Matrix)
library(ggplot2)
library(stringr)
library(data.table)
library(forcats)
library(mltools)
library(ranger)

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

eduction_ordered_labels <- c(" Children" ,
                             " Less than 1st grade",
                             " 1st 2nd 3rd or 4th grade",
                             " 5th or 6th grade",
                             " 7th and 8th grade",
                             " 9th grade",
                             " 10th grade",
                             " 11th grade",
                             " 12th grade no diploma",
                             " High school graduate" ,
                             " Some college but no degree",  
                             " Associates degree-occup /vocational",
                             " Associates degree-academic program" ,
                             " Bachelors degree(BA AB BS)" ,
                             " Masters degree(MA MS MEng MEd MSW MBA)",
                             " Doctorate degree(PhD EdD)",
                             " Prof school degree (MD DDS DVM LLB JD)")


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



# on supprime les colonnes :
# - "migrations..." qui comportent 50 % de données manquantes
# - "country..." peu discrimantes 
#   (41 modalités rares sur 42 modalités (dont 40 avec une fréquence d'appparition inférieure à 1%) 
#   et une variation du niveau de revenu de faible amplitude sur l'ensemble des modalités.
# - "state.of.previous.residence" pour la même raison
# - "detailed.household.and.family.stat" redondante avec "detailed.household.summary.in.household"
drop.cols <- c("migration.code.change.in.msa",           
               "migration.code.change.in.reg",           
               "migration.code.move.within.reg",        
               "migration.prev.res.in.sunbelt",
               "country.of.birth.father",
               "country.of.birth.mother",
               "country.of.birth.self",
               "state.of.previous.residence",
               "detailed.household.and.family.stat")



training <-  data_train %>% select(-one_of(drop.cols))
testing <-  data_test %>% select(-one_of(drop.cols))


# creation d'un échantillon stratifié contenant 40% de la population
# on utilise cetéchantillon pour l'hypertuning
ratio <-0.4
set.seed(1)
strate1<- which(training$outcome == "+50000")
strate0<- which(training$outcome == "-50000")
ech.strat.1<-strate1[sample(seq(length(strate1)),
                            size=ceiling(length(strate1)*ratio))]
ech.strat.0<-strate0[sample(seq(length(strate0)),
                            size=ceiling(length(strate0)*ratio))]
ech.strat<-c(ech.strat.1,ech.strat.0)
training_sample <- training[ech.strat,]

Sys.time()



# tuning : on recherche la valeur optimale du paramètre mtry  
# (nombre de variables tirées alétoirement à chaque noeud de l'arbre)
set.seed(7)
trControl <- trainControl(method="cv", number=5,search="grid", verboseIter = TRUE)
tuneGrid <- expand.grid(mtry=c(10,15,20,25,30,35,40,45),splitrule="gini",min.node.size=1)

metric <- "Accuracy"

rangerTuning <- train(outcome~., data=training_sample, method="ranger", metric=metric,tuneGrid=tuneGrid, trControl=trControl)


# on extrait le paramètre mtry optimal et on l'utilise pour créer le modèle final
# sur l'ensemble des données d'apprentissage
tuneGrid$mtry <- rangerTuning$bestTune$mtry


Sys.time()
rangerFinal <- train(outcome~., data=training, method="ranger", metric=metric,tuneGrid=tuneGrid, trControl=trControl)

Sys.time()
predictions<-predict.train(object=rangerFinal,testing)
Sys.time()

write.csv(predictions, "predictions.csv",row.names = FALSE)