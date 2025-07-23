pacotes <- c("caret","e1071", "mlbench", "mice")

# Instalando e carregando os pacotes necessarios
if(sum(as.numeric(!pacotes %in% installed.packages()))!=0){
  instalador <- pacotes[!pacotes %in% installed.packages()]
  for(i in 1:length(instalador)) {
    install.packages(instalador, dependencies = T)
    break()}
  sapply(pacotes, require, character = T)
} else {
  sapply(pacotes, require, character = T)
}

# Configurando o seed
SEED <- 2038
set.seed(SEED)

# função para dividir as bases
split_train_test <- function(df, target_var) {
  set.seed(SEED)
  indexes <- createDataPartition(df[[target_var]], p=0.80, list=FALSE)
  train <- df[indexes,]
  test <- df[-indexes, ]
  return(list(train=train, test=test))
}

print_cf <- function(name, df_test, cf_factor, model) {
  print(paste("Estimativas do modelo: ", name))
  predict.model <- predict(model, df_test)
  
  print("Confusion matrix")
  print(confusionMatrix(predict.model, cf_factor))
  
  return(predict.model)
}



setwd("C:/Users/rodri/machine-learning/UFPR-IAAP/IAA008 - Aprendizado de máquina")

# Diabetes

df_diabetes <- read.csv("base/10 - Diabetes/10 - Diabetes - Dados.csv")
#View(df_diabetes)
temp_df <- df_diabetes
temp_df$num <- NULL
imp <- mice(temp_df)
df_diabetes <- complete(imp, 1)
df_diabetes[["diabetes"]] <- as.factor(df_diabetes[["diabetes"]])
View(df_diabetes)

# Divisão da base de dados
split_df <- split_train_test(df_diabetes, "diabetes")
train_diabetes = split_df$train
test_diabetes = split_df$test

diabetes_fct <- as.factor(test_diabetes$diabetes)
ctrl <- trainControl(method="cv", number=10)

# KNN
tuneGrid_knn <- expand.grid(k=c(1,3,5,7,9))
set.seed(SEED)
knn <- train(diabetes~., data=train_diabetes, method = "knn", tuneGrid = tuneGrid_knn)
knn
predict.knn <- print_cf("KNN", test_diabetes, diabetes_fct, knn)

# RNA Hold-out
set.seed(SEED)
rna <- train(diabetes~., data=train_diabetes, method = "nnet", trace = FALSE)
rna
predict.rna <- print_cf("RNA hold-out", test_diabetes, diabetes_fct, rna)

# RNA CV
set.seed(SEED)
rna_cv <- train(diabetes~., data=train_diabetes, method = "nnet", trace = FALSE, trControl = ctrl)
rna_cv
predict.rna_cv <- print_cf("RNA CV", test_diabetes, diabetes_fct, rna_cv)

# RNA grid search
grid_rna <- expand.grid(size = seq(from=1,to=45, by=10), decay=seq(from=0.1,to=0.9,by=0.3))
set.seed(SEED)
rna_grid <- train(diabetes~., data=train_diabetes, method = "nnet", trace = FALSE, trControl = ctrl, tuneGrid = grid_rna)
rna_grid
predict.rna_cv_grid <- print_cf("RNA CV grid search", test_diabetes, diabetes_fct, rna_grid)

# SVM
set.seed(SEED)
svm <- train(diabetes~., data = train_diabetes, method = "svmRadial")
svm
predict.svm <- print_cf("SVM hold-out", test_diabetes, diabetes_fct, svm)

# SVM CV
set.seed(SEED)
svm_cv <- train(diabetes~., data = train_diabetes, method = "svmRadial", trControl = ctrl)
svm_cv
predict.svm_cv <- print_cf("SVM CV", test_diabetes, diabetes_fct, svm_cv)

# SVM CV Grid
grid_cv <- expand.grid(C=c(1,2,10,50,100), sigma=c(.01,.015,.2))
set.seed(SEED)
svm_cv_grid <- train(diabetes~., data = train_diabetes, method = "svmRadial", trControl = ctrl, tuneGrid=grid_cv)
svm_cv_grid
predict.svm_cv_grid <- print_cf("SVM CV grid search", test_diabetes, diabetes_fct, svm_cv_grid)

# Randon forest
set.seed(SEED)
rf <- train(diabetes~., data = train_diabetes, method="rf")
rf
predict.rf <- print_cf("RF hold-out", test_diabetes, diabetes_fct, rf)

# RF CV
set.seed(SEED)
rf_cv <- train(diabetes~., data = train_diabetes, method="rf", trControl = ctrl)
rf_cv
predict.rf_cv <- print_cf("RF CV", test_diabetes, diabetes_fct, rf_cv)

# RF CV grid search
grid_rf = expand.grid(mtry=c(2,5,7,9))
set.seed(SEED)
rf_cv_grid <- train(diabetes~., data = train_diabetes, method="rf", trControl = ctrl, tuneGrid = grid_rf)
rf_cv_grid
predict.rf_cv_grid <- print_cf("RF CV grid search", test_diabetes, diabetes_fct, rf_cv_grid)

### Predições
new_data <- read.csv("base/10 - Diabetes/10 - Diabetes - Dados - Novos Casos.csv")
View(new_data)

predict.rf <- predict(rf_cv_grid, new_data)
new_data$diabetes <- NULL
result <- cbind(new_data, predict.rf)
View(result)

