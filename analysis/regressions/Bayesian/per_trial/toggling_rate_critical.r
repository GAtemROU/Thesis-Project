library(stats)
library(tidyverse)
library(lme4)
library(scales)
library(emmeans)
library(magrittr)
library(brms)


df <- read.csv("analysis/data/final_datasets/final_experiment_trials.csv")

df <- df %>%
    filter(Correct == 1) %>%
    filter(Condition %in% c("complex", "simple")) %>%
    mutate(Subject = factor(Subject)) %>%
    mutate(Trial = scale(Trial)) %>%
    mutate(Condition = factor(Condition, levels = 
                c("complex", "simple"))) %>%
    mutate(MsgType = factor(MsgType, levels = c("shape", "color"))) %>%
    mutate(TrgtPos = factor(TrgtPos, levels = c(1, 0, 2))) %>%
    mutate(AnswerTime = scale(AnswerTime)) %>%
    mutate(RateTogglingAvailableMsgs = scale(RateTogglingAvailableMsgs, scale = FALSE))

df_tog_rate <- df %>%
  select(Subject, Trial, Condition, Correct,
         RateTogglingAvailableMsgs, MsgType,
         TrgtPos, AnswerTime)

contrasts(df_tog_rate$Condition) <- c(-1, 1)
contrasts(df_tog_rate$Condition)

contrasts(df_tog_rate$MsgType) <- c(-1, 1)
contrasts(df_tog_rate$MsgType)

contrasts(df_tog_rate$TrgtPos) <- contr.treatment(3)
contrasts(df_tog_rate$TrgtPos)

print(head(df_tog_rate))

regression <- brm(
    RateTogglingAvailableMsgs ~ Condition + TrgtPos + Trial +
    MsgType + AnswerTime + (1 + Condition + TrgtPos + Trial +
    MsgType + AnswerTime | Subject),
    # specify dataset
    data = df_tog_rate,
    # specify to fit a logistic regression
    prior = c(prior(normal(0, 1), class="Intercept"),
              prior(normal(0, 5), class="b")),
    cores = 5,
    save_pars = save_pars(all = TRUE),
    iter = 5000,
    chains = 5,
    warmup = 500,
    control = list(adapt_delta = 0.9)
)



print(summary(regression))
plot(pairs(saved_regr))

sink(file = "analysis/regressions/Bayesian/per_trial/results/toggling_rate_critical.txt")
print(summary(regression), digits = 5)
sink()


# saveRDS(regression, file = paste0("analysis/regressions/Bayesian/per_trial/trained_models/tog_rate.rds"))

# saved_regr = readRDS(file = "/home/gatemrou/uds/thesis/Thesis-Project/analysis/regressions/Bayesian/per_trial/trained_models/tog_rate.rds")


# sink(file = "analysis/regressions/Bayesian/per_trial/results/toggling_rate_critical.txt")
# print(summary(saved_regr), digits = 5)
    
# emmns = emmeans(saved_regr, specs = pairwise ~ Condition : StrategyLabel)
# print(emmns$emmeans)
# print(emmns$contrasts)
# sink()
# emmip(saved_regr, Condition ~ StrategyLabel, cov.reduce = range)
