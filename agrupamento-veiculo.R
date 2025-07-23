# Configurando o seed
SEED <- 2038
set.seed(SEED)

setwd("C:/Users/rodri/machine-learning/UFPR-IAAP/IAA008 - Aprendizado de máquina")

# Veículos

df_veiculos <- read.csv("base/06 - Veículos/6 - Veiculos - Dados.csv")
View(df_veiculos)

# Ignora a coluna de id e coluna de classes
df_veiculos_clean <- df_veiculos[, -c(1, ncol(df_veiculos))]
df_veiculos_clean = scale(df_veiculos_clean)
View(df_veiculos_clean)

veiculos_cluster <- kmeans(df_veiculos_clean, 10)
veiculos_cluster

table(veiculos_cluster$cluster, df_veiculos$tipo)

resultado <- cbind(df_veiculos, veiculos_cluster$cluster)
View(resultado)
