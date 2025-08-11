library(stats)
library(tidyverse)
library(lme4)
library(scales)
library(emmeans)
library(magrittr)
library(brms)
library(glmnet)
library(languageserver)
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

df <- read.csv("analysis/data/gaze_simulations/preprocessed_simulation_responses_correct.csv")

df <- df %>%
    filter(Condition %in% c("complex", "simple")) %>%
    mutate(Correct = ifelse(Correct == "True", 1, 0)) %>%
    mutate(Subject = factor(Subject)) %>%
    mutate(Trial = scale(Trial)) %>%
    mutate(Condition = factor(Condition, levels = 
                c("complex", "simple"))) %>%
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
         PropTimeOnAvailableMsgs,
         RateTogglingAvailableMsgs, AnswerTime, StrategyLabel)


contrasts(df_correct$Condition) <- c(-1, 1)
contrasts(df_correct$Condition)

print(head(df_correct))


av_msgs_plot <- ggplot(data = df_correct) + aes(x = PropTimeOnAvailableMsgs) + geom_histogram() +
  facet_grid(rows = vars(Condition, Correct), cols = vars(StrategyLabel))

# save av_msgs_plot
ggsave("analysis/regressions/MLE/sim_plots/sim_av_msgs_plot.png", plot = av_msgs_plot, width = 10, height = 6)


ggplot(data = df_correct) + aes(x = RateTogglingAvailableMsgs) + geom_histogram() +
  facet_grid(rows = vars(Condition, Correct), cols = vars(StrategyLabel))


lasso_formula <- Correct ~ Condition + Trial +  PropTimeOnTrgt +
    PropTimeOnComp + PropTimeOnDist +
    PropTimeOnAvailableMsgs + 
    RateTogglingAvailableMsgs + AnswerTime +
    Condition:PropTimeOnTrgt + Condition:PropTimeOnComp +
    Condition:PropTimeOnDist +
    Condition:PropTimeOnAvailableMsgs +
    Condition:RateTogglingAvailableMsgs + Condition:AnswerTime


lasso <- glmnet(
    x = model.matrix(lasso_formula, data = df_correct)[, -1],
    y = df_correct$Correct,
    family = "binomial",
    alpha = 1,
    standardize = FALSE
)

print(lasso)
plot(lasso)

cvfit <- cv.glmnet(
    x = model.matrix(lasso_formula, data = df_correct)[, -1],
    y = df_correct$Correct,
    family = "binomial",
    alpha = 1)

coef(cvfit, s = "lambda.min")
coef(cvfit, s = "lambda.1se")

# regression <- glm(
#     Correct ~ Condition + Trial +  PropTimeOnTrgt +
#     PropTimeOnComp + PropTimeOnDist +
#     PropTimeOnAvailableMsgs + 
#     RateTogglingAvailableMsgs + AnswerTime +
#     Condition:PropTimeOnTrgt + Condition:PropTimeOnComp +
#     Condition:PropTimeOnDist +
#     Condition:PropTimeOnAvailableMsgs +
#     Condition:RateTogglingAvailableMsgs + Condition:AnswerTime,
#     # (1 + Condition
#     #  + Trial + PropTimeOnTrgt +
#     # # PropTimeOnComp + PropTimeOnDist + PropTimeOnSentMsg +
#     # # PropTimeOnAvailableMsgs + RateTogglingAvailableMsgs 
#     # | Subject),
#     # specify dataset
#     data = df_correct,
#     # specify to fit a logistic regression
#     family = binomial(link = "logit")
# )
# beep(sound = 3)

print(summary(regression))

saveRDS(regression, file = paste0("analysis/regressions/Bayesian/per_trial/trained_models/sim_cor_ans_regr_", format(Sys.time(), "%F_%R"), ".rds"))

saved_regr = readRDS("/home/gatemrou/uds/thesis/Thesis-Project/analysis/regressions/Bayesian/per_trial/trained_models/sim_cor_ans_regr_2025-07-20_11:48.rds")
as_draws_df(fit_press)
condEffects(saved_regr, "Condition")
print(summary(saved_regr))
for (aoi in c("PropTimeOnTrgt", "PropTimeOnComp", "PropTimeOnDist", "PropTimeOnAvailableMsgs")) {
  emtr = emtrends(regression, specs = pairwise ~ Condition, var = aoi, 
                mode = "latent", 
                data = df_correct)
  print(emtr$emtrends)
  print(emtr$contrasts)
}
emtr = emtrends(saved_regr, specs = pairwise ~ Condition, var = "RateTogglingAvailableMsgs", 
                mode = "latent", 
                data = df_correct)
print(emtr$emtrends)
print(emtr$contrasts)

emmip(regression, Condition ~ AnswerTime, cov.reduce = range)

