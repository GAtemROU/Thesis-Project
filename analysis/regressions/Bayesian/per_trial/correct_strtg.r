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
    mutate(StrategyLabel = factor(StrategyLabel, levels = c(0, 1, 2)))


df_correct <- df %>%
  select(Subject, Trial, Condition, Correct, MsgType,
         TrgtPos, AnswerTime, StrategyLabel)


contrasts(df_correct$Condition) <- c(-1, 1)
contrasts(df_correct$Condition)

contrasts(df_correct$MsgType) <- c(-1, 1)
contrasts(df_correct$MsgType)

contrasts(df_correct$TrgtPos) <- contr.treatment(3)
contrasts(df_correct$TrgtPos)

contrasts(df_correct$StrategyLabel) <- contr.helmert(3)
contrasts(df_correct$StrategyLabel)

print(head(df_correct))

regression <- brm(
    Correct ~ Condition + TrgtPos + Trial +
    StrategyLabel + MsgType + AnswerTime +
    Condition:StrategyLabel + Condition:AnswerTime +
    (1 + Condition + TrgtPos + Trial +
    StrategyLabel + MsgType + AnswerTime | Subject),
    # specify dataset
    data = df_correct,
    # specify to fit a logistic regression
    family = "bernoulli",
    prior = c(prior(normal(1, 2), class="Intercept"),
              prior(normal(0, 5), class="b")),
    cores = 6,
    save_pars = save_pars(all = TRUE),
    iter = 5000,
    chains = 6,
    warmup = 1000,
    control = list(adapt_delta = 0.9),
)
# beep(sound = 3)


sink(file = "analysis/regressions/Bayesian/per_trial/results/correct_strtg.txt")
print(summary(regression))
emmns = emmeans(regression, specs = pairwise ~ Condition : StrategyLabel)
print(emmns$emmeans)
print(emmns$contrasts)
sink()

saveRDS(regression, file = paste0("analysis/regressions/Bayesian/per_trial/trained_models/cor_strtg_", format(Sys.time(), "%F_%R"), ".rds"))

saved_regr = readRDS("/home/gatemrou/uds/thesis/Thesis-Project/analysis/regressions/Bayesian/per_trial/trained_models/cor_strtg_2025-08-16_19:27.rds")
# as_draws_df(fit_press)
# condEffects(saved_regr, "Condition")
sink(file = "analysis/regressions/Bayesian/per_trial/results/correct_strtg.txt")
print(summary(saved_regr))
emmns = emmeans(saved_regr, specs = pairwise ~ Condition : StrategyLabel)
print(emmns$emmeans)
print(emmns$contrasts)
sink()


emmip(regression, Condition ~ AnswerTime, cov.reduce = range)

