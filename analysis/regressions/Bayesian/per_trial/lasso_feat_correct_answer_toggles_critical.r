library(stats)
library(tidyverse)
library(lme4)
library(scales)
library(emmeans)
library(magrittr)
library(brms)
# library(beepr)

condEffects <- function(model, x, facet_by = c()){
  if (length(facet_by)>0) {
    conditions <- make_conditions(model, facet_by)  } else {
    conditions <- NULL
  }
  
  effects <- conditional_effects(model, effects = x, 
                                 conditions = conditions)
  
  return(effects)
}

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
    Correct ~ Condition + TrgtPos + Trial +  PropTimeOnTrgt +
    PropTimeOnComp + 
    # PropTimeOnDist + , dropped by lasso 
    PropTimeOnSentMsg + 
    PropTimeOnAvailableMsgs + 
    RateTogglingAvailableMsgs +
    MsgType + 
    # AnswerTime +
    Condition:PropTimeOnTrgt + 
    # Condition:PropTimeOnComp +
    # Condition:PropTimeOnDist + 
    # Condition:PropTimeOnSentMsg +
    # Condition:PropTimeOnAvailableMsgs +
    Condition:RateTogglingAvailableMsgs + Condition:AnswerTime +
    (1 + Condition + TrgtPos + Trial + PropTimeOnTrgt +
    PropTimeOnComp + PropTimeOnAvailableMsgs + RateTogglingAvailableMsgs + MsgType | Subject),
    # specify dataset
    data = df_correct,
    # specify to fit a logistic regression
    family = "bernoulli",
    prior = c(prior(normal(1, 2), class="Intercept"),
              prior(normal(0, 5), class="b")),
    cores = 6,
    save_pars = save_pars(all = TRUE),
    iter = 2000,
    chains = 6,
    warmup = 500

)
# beep(sound = 3)

print(summary(regression))

saveRDS(regression, file = paste0("analysis/regressions/Bayesian/per_trial/trained_models/cor_ans_regr_", format(Sys.time(), "%F_%R"), ".rds"))

saved_regr = readRDS("/home/gatemrou/uds/thesis/Thesis-Project/analysis/regressions/Bayesian/per_trial/trained_models/cor_ans_regr_2025-07-01_15:44.rds")
as_draws_df(fit_press)
condEffects(saved_regr, "Condition")
print(summary(saved_regr))
emtr = emtrends(saved_regr, specs = pairwise ~ Condition, var = 'RateTogglingAvailableMsgs')
print(emtr$emtrends)
print(emtr$contrasts)
emmip(regression, Condition ~ AnswerTime, cov.reduce = range)

