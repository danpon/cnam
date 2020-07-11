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
library(kernlab)

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



# on supprime les colonnes :
# - "migrations..." qui comportent 50 % de données manquantes
# - "country..." peu discrimantes 
#   (41 modalités rares sur 42 modalités (dont 40 avec une fréquence d'appparition inférieure à 1%) 
#   et une variation du niveau de revenu de faible amplitude sur l'ensemble des modalités.
# - "state.of.previous.residence" pour la même raison
# - "detailed.household.and.family.stat" redondante avec "detailed.household.summary.in.household"
# - "detailed.industry.recode." redondante avec "major.industry.code"
# - detailed.occupation.recode redondante avec "major.occupation.code"
drop.cols <- c("migration.code.change.in.msa",           
               "migration.code.change.in.reg",           
               "migration.code.move.within.reg",        
               "migration.prev.res.in.sunbelt",
               "country.of.birth.father",
               "country.of.birth.mother",
               "country.of.birth.self",
               "state.of.previous.residence",
               "detailed.household.and.family.stat",
               "detailed.industry.recode.",
               "detailed.occupation.recode"
               )



training <-  data_train %>% select(-one_of(drop.cols))
testing <-  data_test %>% select(-one_of(drop.cols))



# Discrétisation de "capital.gains","capital.losses","from.stocks","wage.per.hour"
# en varaiables bianires
vars.0.spike <- c("capital.gains","capital.losses","from.stocks","wage.per.hour")
for(v in vars.0.spike)
{
    training[training[[v]]>0,v] <- 1
    training[[v]] <- as.factor(training[[v]])
    testing[testing[[v]]>0,v] <- 1
    testing[[v]] <- as.factor(testing[[v]])
}



# creation d'un échantillon stratifié contenant 10% de la population
# on utilise cet échantillon pour l'hypertuning
ratio <-0.4
set.seed(1)
strate1<- which(training$outcome == "+50000")
strate0<- which(training$outcome == "-50000")
ech.strat.1<-strate1[sample(seq(length(strate1)),
                            size=ceiling(length(strate1)*ratio))]
ech.strat.0<-strate0[sample(seq(length(strate0)),
                            size=ceiling(length(strate0)*ratio))]

# échantillon des numéros de lignes  utilisé pour l'apprentissage
ech.strat_learning<-c(ech.strat.1,ech.strat.0)

# numéros de lignes restantes, utilisées pour la validation
ech.strat_validation<- setdiff(seq(nrow(training)), ech.strat_learning)

training_sample <- training[ech.strat_learning,]
test_sample <- training[ech.strat_validation,]

costs <- c(0.1, 0.25, 0.5 ,1,2,4,8,16)

bestCost <- 0
bestError <-1


for( cost in costs)
{    
    print(paste(Sys.time(),"cost",cost,sep = " "))
    
    model <- ksvm(outcome ~ ., training_sample,  kernel="rbfdot", scaled=TRUE,C=cost,cross=5)

    pred <- predict(model,test_sample)
    
    test_sample$prediction <- pred
    
    error <- nrow(test_sample[test_sample$outcome!=test_sample$prediction,])/nrow(test_sample)

    if(error < bestError){
        bestError <-error
        bestCost <- cost
        print(paste("!!!! bestError",bestError," bestCost",bestCost,sep=" "))
        write.csv(pred, "predictions.csv",row.names = FALSE)
    }    
}

print(paste("!!!! bestError",bestError," bestCost",bestCost,sep=" "))