pacotes <- c("caret", "ggplot2")

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

r2 <- function(predicted, real) {
  return ( 1 - (sum((predicted - real)^2) / sum((real - mean(real))^2)))
}

syx <- function(predicted, real, p){
  n <- length(predicted)
  return (sqrt(sum((real - predicted) ^ 2) / (n - p)))
}

pearson <- function(predicted, real) {
  x_mean <- mean(real)
  y_mean <- mean(predicted)
  # cor(predicted, real, method = "pearson")
  return(sum((real - x_mean) * (predicted - y_mean)) / (sqrt(sum((real - x_mean) ^ 2)) * sqrt(sum((predicted - y_mean) ^ 2))))
}

print_model_stats <- function(name, df_test, target_var, model, number_features, df_stats) {
  predicted <- predict(model, df_test)
  observed <- df_test[[target_var]]
  
  
  r2 <- r2(predicted, observed)
  syx <- syx(predicted, observed, number_features)
  pearson <- pearson(predicted, observed)
  rmse <- RMSE(predicted, observed)
  mae <- MAE(predicted, observed)
  
  cat("Estatísticas do modelo:", name, "\n")
  cat("R2      -->", r2, "\n")
  cat("Syx     -->", syx, "\n")
  cat("Pearson -->", pearson, "\n")
  cat("RMSE    -->", rmse, "\n")
  cat("MAE     -->", mae, "\n\n")
  
  new_row <- data.frame(
    Modelo = name,
    R2 = r2,
    Syx = syx,
    Pearson = pearson,
    RMSE = rmse,
    MAE = mae,
    stringsAsFactors = FALSE
  )
  
  return(rbind(df_stats, new_row))
}

# Configurando o seed
SEED <- 2038
set.seed(SEED)

setwd("C:/Users/rodri/machine-learning/UFPR-IAAP/IAA008 - Aprendizado de máquina")

# Admissão

df_admissao <- read.csv("base/09 - Admissão/9 - Admissao - Dados.csv")
df_admissao$num <- NULL
View(df_admissao)

target_var <- "ChanceOfAdmit"
number_features <- ncol(df_admissao) - 1

df_stats <- data.frame(
  Modelo = character(),
  R2 = numeric(),
  Syx = numeric(),
  Pearson = numeric(),
  RMSE = numeric(),
  MAE = numeric(),
  stringsAsFactors = FALSE
)

# Divisão da base de dados
set.seed(SEED)
indexes <- createDataPartition(df_admissao[[target_var]], p=0.80, list=FALSE)
train <- df_admissao[indexes,]
test <- df_admissao[-indexes, ]

ctrl <- trainControl(method="cv", number=10)

# KNN
tuneGrid_knn <- expand.grid(k=c(1,3,5,7,9))
set.seed(SEED)
knn <- train(ChanceOfAdmit~., data=train, method = "knn", tuneGrid = tuneGrid_knn)
knn
df_stats <- print_model_stats("KNN", test, target_var, knn, number_features, df_stats)

# RNA Hold-out
set.seed(SEED)
rna <- train(ChanceOfAdmit~., data=train, method = "nnet", linout=T, trace = FALSE)
rna
df_stats <- print_model_stats("RNA hold-out", test, target_var, rna, number_features, df_stats)

# RNA grid search
grid_rna <- expand.grid(size = seq(from=1,to=45, by=10), decay=seq(from=0.1,to=0.9,by=0.3))
set.seed(SEED)
rna_grid <- train(ChanceOfAdmit~., data=train, method = "nnet", linout=T, trace = FALSE, trControl = ctrl, tuneGrid = grid_rna, MaxNWts=10000, maxit=2000)
rna_grid
df_stats <- print_model_stats("RNA CV grid search", test, target_var, rna_grid, number_features, df_stats)

# SVM
set.seed(SEED)
svm <- train(ChanceOfAdmit~., data = train, method = "svmRadial")
svm
df_stats <- print_model_stats("SVM hold-out", test, target_var, svm, number_features, df_stats)

# SVM CV
set.seed(SEED)
svm_cv <- train(ChanceOfAdmit~., data = train, method = "svmRadial", trControl = ctrl)
svm_cv
df_stats <- print_model_stats("SVM CV", test, target_var, svm_cv, number_features, df_stats)

# SVM CV Grid
grid_cv <- expand.grid(C=c(1,2,10,50,100), sigma=c(.01,.015,.2))
set.seed(SEED)
svm_cv_grid <- train(ChanceOfAdmit~., data = train, method = "svmRadial", trControl = ctrl, tuneGrid=grid_cv)
svm_cv_grid
df_stats <- print_model_stats("SVM CV grid search", test, target_var, svm_cv_grid, number_features, df_stats)

# Randon forest
set.seed(SEED)
rf <- train(ChanceOfAdmit~., data = train, method="rf")
rf
df_stats <- print_model_stats("RF hold-out", test, target_var, rf, number_features, df_stats)

# RF CV
set.seed(SEED)
rf_cv <- train(ChanceOfAdmit~., data = train, method="rf", trControl = ctrl)
rf_cv
df_stats <- print_model_stats("RF CV", test, target_var, rf_cv, number_features, df_stats)

# RF CV grid search
grid_rf = expand.grid(mtry=c(2,5,7,9))
set.seed(SEED)
rf_cv_grid <- train(ChanceOfAdmit~., data = train, method="rf", trControl = ctrl, tuneGrid = grid_rf)
rf_cv_grid
df_stats <- print_model_stats("RF CV grid search", test, target_var, rf_cv_grid, number_features, df_stats)

df_stats <- df_stats[order(-df_stats$R2), ]

View(df_stats)

### Novas predições
new_data <- read.csv("base/09 - Admissão/9 - Admissao - Dados - Novos Casos.csv")
View(new_data)

predict.svm_cv <- predict(svm_cv, new_data)
new_data$ChanceOfAdmit <- NULL
result <- cbind(new_data, predict.svm_cv)
View(result)


##### Gráfico de resíduos do melhor modelo
svm.pred <- predict(svm_cv, test)
obs <- test$ChanceOfAdmit

df_residual <- data.frame(
  Predito = svm.pred,
  Observado = obs,
  Resíduo = (((obs - svm.pred) / obs) * 100)
)

ggplot(df_residual, aes(x = Predito, y = Resíduo)) +
  geom_point(color = "steelblue") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  labs(title = "Gráfico de Resíduos do modelo SVM CV",
       x = "Chance de admissão estimado",
       y = "Resíduos (%)") +
  theme_minimal()

