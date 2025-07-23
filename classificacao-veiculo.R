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

# Veículos

df_veiculos <- read.csv("base/06 - Veículos/6 - Veiculos - Dados.csv")
#View(df_veiculos)
temp_df <- df_veiculos
temp_df$a <- NULL
imp <- mice(temp_df)
df_veiculos <- complete(imp, 1)
df_veiculos[["tipo"]] <- as.factor(df_veiculos[["tipo"]])
View(df_veiculos)

# Divisão da base de dados
split_df <- split_train_test(df_veiculos, "tipo")
train_veiculo = split_df$train
test_veiculo = split_df$test

tipo_fct <- as.factor(test_veiculo$tipo)

ctrl <- trainControl(method="cv", number=10)

# KNN
tuneGrid_knn <- expand.grid(k=c(1,3,5,7,9))
set.seed(SEED)
knn <- train(tipo~., data=train_veiculo, method = "knn", tuneGrid = tuneGrid_knn)
knn
predict.knn <- print_cf("KNN", test_veiculo, tipo_fct, knn)

# RNA Hold-out
set.seed(SEED)
rna <- train(tipo~., data=train_veiculo, method = "nnet", trace = FALSE)
rna
predict.rna <- print_cf("RNA hold-out", test_veiculo, tipo_fct, rna)

# RNA CV
set.seed(SEED)
rna_cv <- train(tipo~., data=train_veiculo, method = "nnet", trace = FALSE, trControl = ctrl)
rna_cv
predict.rna_cv <- print_cf("RNA CV", test_veiculo, tipo_fct, rna_cv)

# RNA grid search
grid_rna <- expand.grid(size = seq(from=1,to=45, by=10), decay=seq(from=0.1,to=0.9,by=0.3))
set.seed(SEED)
rna_grid <- train(tipo~., data=train_veiculo, method = "nnet", trace = FALSE, trControl = ctrl, tuneGrid = grid_rna)
rna_grid
predict.rna_cv_grid <- print_cf("RNA CV grid search", test_veiculo, tipo_fct, rna_grid)

# SVM
set.seed(SEED)
svm <- train(tipo~., data = train_veiculo, method = "svmRadial")
svm
predict.svm <- print_cf("SVM hold-out", test_veiculo, tipo_fct, svm)

# SVM CV
set.seed(SEED)
svm_cv <- train(tipo~., data = train_veiculo, method = "svmRadial", trControl = ctrl)
svm_cv
predict.svm_cv <- print_cf("SVM CV", test_veiculo, tipo_fct, svm_cv)

# SVM CV Grid
grid_cv <- expand.grid(C=c(1,2,10,50,100), sigma=c(.01,.015,.2))
set.seed(SEED)
svm_cv_grid <- train(tipo~., data = train_veiculo, method = "svmRadial", trControl = ctrl, tuneGrid=grid_cv)
svm_cv_grid
predict.svm_cv_grid <- print_cf("SVM CV grid search", test_veiculo, tipo_fct, svm_cv_grid)

# Randon forest
set.seed(SEED)
rf <- train(tipo~., data = train_veiculo, method="rf")
rf
predict.rf <- print_cf("RF hold-out", test_veiculo, tipo_fct, rf)

# RF CV
set.seed(SEED)
rf_cv <- train(tipo~., data = train_veiculo, method="rf", trControl = ctrl)
rf_cv
predict.rf_cv <- print_cf("RF CV", test_veiculo, tipo_fct, rf_cv)

# RF CV grid search
grid_rf = expand.grid(mtry=c(2,5,7,9))
set.seed(SEED)
rf_cv_grid <- train(tipo~., data = train_veiculo, method="rf", trControl = ctrl, tuneGrid = grid_rf)
rf_cv_grid
predict.rf_cv_grid <- print_cf("RF CV grid search", test_veiculo, tipo_fct, rf_cv_grid)

### Predições
new_data <- read.csv("base/06 - Veículos/6 - Veiculos - Dados - Novos Casos.csv")
View(new_data)

predict.svm <- predict(svm_cv_grid, new_data)
new_data$tipo <- NULL
result <- cbind(new_data, predict.svm)
View(result)

