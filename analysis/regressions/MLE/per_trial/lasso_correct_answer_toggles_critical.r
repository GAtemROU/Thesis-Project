library(stats)
library(tidyverse)
library(lme4)
library(scales)
library(emmeans)
library(magrittr)
library(glmnet)


df <- read.csv("analysis/data/final_datasets/final_experiment_trials.csv")

df <- df %>%
    filter(Condition %in% c("complex", "simple")) %>%
    mutate(Subject = factor(Subject)) %>%
    mutate(Trial = scale(Trial)) %>%
    mutate(Condition = factor(Condition, levels = 
                c("complex", "simple"))) %>%
    mutate(MsgType = factor(MsgType, levels = c("shape", "color"))) %>%
    mutate(TrgtPos = factor(TrgtPos, levels = c(1, 0, 2))) %>%
    mutate(AnswerTime = scale(AnswerTime)) %>%
    mutate(PropTimeOnSentMsg = scale(PropTimeOnSentMsg, scale = FALSE)) %>%
    mutate(PropTimeOnTrgt = scale(PropTimeOnTrgt, scale = FALSE)) %>%
    mutate(PropTimeOnDist = scale(PropTimeOnDist, scale = FALSE)) %>%
    mutate(PropTimeOnComp = scale(PropTimeOnComp, scale = FALSE)) %>%
    mutate(RateTogglingAvailableMsgs = scale(RateTogglingAvailableMsgs, scale = FALSE)) %>%
    mutate(PropTimeOnAvailableMsgs = scale(PropTimeOnAvailableMsgs, scale = FALSE))

df_correct <- df %>%
  select(Subject, Trial, Condition, Correct, PropTimeOnComp,
         PropTimeOnSentMsg, PropTimeOnTrgt, PropTimeOnDist,
         PropTimeOnAvailableMsgs, PropTimeOnNonAOI,
         RateTogglingAvailableMsgs, MsgType,
         TrgtPos, AnswerTime)

contrasts(df_correct$Condition) <- c(-1, 1)
contrasts(df_correct$Condition)

contrasts(df_correct$MsgType) <- c(-1, 1)
contrasts(df_correct$MsgType)

contrasts(df_correct$TrgtPos) <- contr.treatment(3)
contrasts(df_correct$TrgtPos)

print(head(df_correct))

# Correct ~ Condition + TrgtPos + Trial +  PropTimeOnTrgt +
#     PropTimeOnComp + PropTimeOnDist + PropTimeOnSentMsg +
#     PropTimeOnAvailableMsgs + 
#     RateTogglingAvailableMsgs +
#     MsgType + AnswerTime +
#     Condition:PropTimeOnTrgt + Condition:PropTimeOnComp +
#     Condition:PropTimeOnDist + Condition:PropTimeOnSentMsg +
#     Condition:PropTimeOnAvailableMsgs +
#     Condition:RateTogglingAvailableMsgs + Condition:AnswerTime

lasso_formula <- Correct ~ Condition + TrgtPos + Trial + PropTimeOnTrgt +
    PropTimeOnComp + PropTimeOnDist + PropTimeOnSentMsg +
    PropTimeOnAvailableMsgs + RateTogglingAvailableMsgs +
    MsgType + AnswerTime +
    Condition:PropTimeOnTrgt + Condition:PropTimeOnComp +
    Condition:PropTimeOnDist + Condition:PropTimeOnSentMsg +
    Condition:PropTimeOnAvailableMsgs +
    Condition:RateTogglingAvailableMsgs + Condition:AnswerTime

# Create model matrix and response for lasso
X_lasso <- model.matrix(lasso_formula, df_correct)[, -1] # remove intercept
y_lasso <- df_correct$Correct

lasso <- glmnet(X_lasso, y_lasso,
    family = "binomial",
    alpha = 1)

print(lasso)
plot(lasso)

cvfit <- cv.glmnet(X_lasso, y_lasso,
    family = "binomial",
    alpha = 1)

print(cvfit)
plot(cvfit)

coef(cvfit, s = "lambda.min")
coef(cvfit, s = "lambda.1se")

plot(lasso)

print(summary(lasso))

# saveRDS(regression, file = paste0("analysis/regressions/per_trial/trained_models/cor_ans_regr_", format(Sys.time(), "%F_%R"), ".rds"))

emtr = emtrends(coef(cvfit, s = "lambda.min"), specs = pairwise ~ Condition, var = 'PropTimeOnAvailableMsgs')
print(emtr$emtrends)
print(emtr$contrasts)
emmip(lasso, Condition ~ AnswerTime, cov.reduce = range)
