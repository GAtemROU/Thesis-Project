library(stats)
library(tidyverse)
library(lme4)
library(scales)
library(emmeans)
library(magrittr)
library(brms)


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

regression <- brm(
    Correct | trials(1) ~ Condition + TrgtPos + Trial +  PropTimeOnTrgt +
    PropTimeOnComp + PropTimeOnDist + PropTimeOnSentMsg +
    PropTimeOnAvailableMsgs + 
    RateTogglingAvailableMsgs +
    MsgType + AnswerTime +
    Condition:PropTimeOnTrgt + Condition:PropTimeOnComp +
    Condition:PropTimeOnDist + Condition:PropTimeOnSentMsg +
    Condition:PropTimeOnAvailableMsgs +
    Condition:RateTogglingAvailableMsgs + Condition:AnswerTime +
    (1 + TrgtPos | Subject),
    # specify dataset
    data = df_correct,
    # specify to fit a logistic regression
    family = binomial(link = "logit"),
    prior = c(prior(uniform(0, 1), class=Intercept, lb=0, ub=1)),

)


print(summary(regression))

saveRDS(regression, file = paste0("analysis/regressions/Bayesian/per_trial/trained_models/cor_ans_regr_", format(Sys.time(), "%F_%R"), ".rds"))

# emtr = emtrends(regression, specs = pairwise ~ Condition, var = 'PropTimeOnAvailableMsgs')
# print(emtr$emtrends)
# print(emtr$contrasts)
# emmip(regression, Condition ~ AnswerTime, cov.reduce = range)
# summary(df$RateTogglingAvailableMsgs)

