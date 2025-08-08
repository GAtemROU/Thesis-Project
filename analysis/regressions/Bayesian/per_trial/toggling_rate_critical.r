library(stats)
library(tidyverse)
library(lme4)
library(scales)
library(emmeans)
library(magrittr)
library(brms)
library(xtable)


df <- read.csv("analysis/data/final_datasets/final_experiment_trials.csv")

df <- df %>%
    filter(Condition %in% c("complex", "simple")) %>%
    mutate(Subject = factor(Subject)) %>%
    mutate(Trial = scale(Trial)) %>%
    mutate(Condition = factor(Condition, levels = 
                c("complex", "simple"))) %>%
    mutate(MsgType = factor(MsgType, levels = c("shape", "color"))) %>%
    mutate(TrgtPos = factor(TrgtPos, levels = c(1, 0, 2))) %>%
    mutate(StrategyLabel = factor(StrategyLabel, levels = c(0, 1, 2))) %>% # check !!!
    mutate(AnswerTime = scale(AnswerTime)) %>%
    mutate(PropTimeOnSentMsg = scale(PropTimeOnSentMsg, scale = FALSE)) %>%
    mutate(PropTimeOnTrgt = scale(PropTimeOnTrgt, scale = FALSE)) %>%
    mutate(PropTimeOnDist = scale(PropTimeOnDist, scale = FALSE)) %>%
    mutate(PropTimeOnComp = scale(PropTimeOnComp, scale = FALSE)) %>%
    mutate(RateTogglingAvailableMsgs = scale(RateTogglingAvailableMsgs, scale = FALSE)) %>%
    mutate(PropTimeOnAvailableMsgs = scale(PropTimeOnAvailableMsgs, scale = FALSE))

df_tog_rate <- df %>%
  select(Subject, Trial, Condition, Correct, PropTimeOnComp,
         PropTimeOnSentMsg, PropTimeOnTrgt, PropTimeOnDist,
         PropTimeOnAvailableMsgs, PropTimeOnNonAOI,
         RateTogglingAvailableMsgs, StrategyLabel, MsgType,
         TrgtPos, AnswerTime)

contrasts(df_tog_rate$Condition) <- c(-1, 1)
contrasts(df_tog_rate$Condition)

contrasts(df_tog_rate$StrategyLabel) <- contr.helmert(3)
contrasts(df_tog_rate$StrategyLabel)

contrasts(df_tog_rate$MsgType) <- c(-1, 1)
contrasts(df_tog_rate$MsgType)

contrasts(df_tog_rate$TrgtPos) <- contr.treatment(3)
contrasts(df_tog_rate$TrgtPos)

print(head(df_tog_rate))

# Fit a linear regression model
# regression <- lm(
#   RateTogglingAvailableMsgs ~ Condition + TrgtPos + Trial + 
#     StrategyLabel + Correct + MsgType + AnswerTime +
#     # Condition:PropTimeOnTrgt + Condition:PropTimeOnComp +
#     # Condition:PropTimeOnDist + Condition:PropTimeOnSentMsg +
#     # Condition:PropTimeOnAvailableMsgs + 
#     Condition:StrategyLabel + Condition:AnswerTime,
#   # specify dataset
#   data = df_tog_rate
# )

regression <- brm(
    RateTogglingAvailableMsgs ~ Condition + TrgtPos + Trial +
    StrategyLabel + Correct + MsgType + AnswerTime +
    Condition:StrategyLabel + Condition:AnswerTime +
    (1 + Condition + TrgtPos + Trial +
    StrategyLabel + Correct + MsgType + AnswerTime | Subject),
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
    control = list(adapt_delta = 0.9),

)



print(summary(regression))
plot(pairs(regression))
saveRDS(regression, file = paste0("analysis/regressions/Bayesian/per_trial/trained_models/tog_rate__", format(Sys.time(), "%F_%R"), ".rds"))

saved_regr = readRDS(file = "/home/gatemrou/uds/thesis/Thesis-Project/analysis/regressions/Bayesian/per_trial/trained_models/tog_rate__2025-08-08_23:38.rds")
print(summary(saved_regr), digits = 5)
    
emtr = emtrends(saved_regr, specs = pairwise ~ Condition, var = 'StrategyLabel')
print(emtr$emtrends)
print(emtr$contrasts)
emmns = emmeans(saved_regr, specs = pairwise ~ Condition : StrategyLabel)
print(emmns$emmeans)
print(emmns$contrasts)
print(emmns)
emmip(regression, Condition ~ StrategyLabel, cov.reduce = range)




# TeX

coef_table <- posterior_summary(saved_regr, variables = "^b_")  # only fixed effects
coef_df <- as.data.frame(coef_table)
coef_df$Term <- rownames(coef_df)

# Optional: reorder columns and round
coef_df <- coef_df[, c("Term", "Estimate", "Est.Error", "Q2.5", "Q97.5")]
coef_df <- round(coef_df, 5)  # exactly 5 decimal places

# Create LaTeX table
print(xtable(coef_df,
             caption = "Regression coefficients from brms model",
             label = "tab:brms_coefs"),
      include.rownames = FALSE,
      sanitize.text.function = identity) 
