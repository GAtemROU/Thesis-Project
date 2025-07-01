library(stats)
library(tidyverse)
library(lme4)
library(scales)

df <- read.csv("analysis/data/final_datasets/final_experiment_correct_fixations.csv")
# 'Subject', 'Trial', 'Condition', 'MsgType', 'TrgtPos', 'Time', 'AOI'

df <- df %>%
    mutate(Subject = factor(Subject)) %>%
    mutate(Trial = scale(Trial)) %>%
    mutate(Condition = factor(Condition, levels = 
                c("complex", "simple", "unambiguous"))) %>%
    mutate(MsgType = factor(MsgType, levels = c("shape", "color"))) %>%
    mutate(TrgtPos = factor(TrgtPos, levels = c(1, 0, 2)))

df_on_dist <- df %>%
    mutate(OnDist = AOI == "dist") %>%
    select(Subject, Trial, Condition, MsgType, TrgtPos, Time, OnDist)

contrasts(df_on_dist$Condition) <- contr.helmert(3)
contrasts(df_on_dist$Condition)

contrasts(df_on_dist$MsgType) <- c(-1, 1)
contrasts(df_on_dist$MsgType)

contrasts(df_on_dist$TrgtPos) <- contr.treatment(3)
contrasts(df_on_dist$TrgtPos)

print(head(df_on_dist))

# fitting logistic regression with an intercept plus 4 slopes,
# and associated random effects by subject
regression <- glmer(
    OnDist ~ Condition + Trial + MsgType + TrgtPos +
        (1 | Subject),
    # specify dataset
    data = df_on_dist,
    # specify to fit a logistic regression
    family = binomial(link = "logit"),
    verbose = TRUE
)


print(summary(regression))

saveRDS(regression, file = paste0("/home/gatemrou/uds/thesis/Thesis-Project/analysis/regressions/per_correct_fixation/trained_models/on_dist_regr_", format(Sys.time(), "%F_%R"), ".rds"))

