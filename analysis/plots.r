library(GGally)

df <- read.csv("analysis/data/final_datasets/final_experiment_participants.csv")

GGally::ggpairs(df, columns = 2:28)
