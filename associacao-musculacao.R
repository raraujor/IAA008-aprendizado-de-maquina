#install.packages('arules', dep=T)
library(arules)
library(datasets)

# Configurando o seed
SEED <- 2038
set.seed(SEED)

setwd("C:/Users/rodri/machine-learning/UFPR-IAAP/IAA008 - Aprendizado de máquina")

atividades <- read.transactions(
  file = "base/12 - Regras de Associacao - Praticas/12 - Regras de Associacao - Praticas – 2 - Musculacao/2 - Musculacao - Dados.csv",
  format = "basket",
  sep=";"
  )

inspect(head(atividades, 3))
itemFrequencyPlot(atividades, topN = 10, type='absolute')

summary(atividades)

set.seed(SEED)
rules <- apriori(atividades, parameter = list(supp = 0.001, conf = 0.7, minlen=2))
summary(rules)

options(digits=2)
inspect(sort(rules, by="confidence"))
