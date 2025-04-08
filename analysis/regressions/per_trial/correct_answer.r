library(stats)
library(tidyverse)
library(lme4)
library(scales)
library(emmeans)
library(magrittr)


df <- read.csv("analysis/data/final_datasets/final_experiment_trials.csv")
# 'Subject', 'Trial', 'Condition', 'MsgType', 'TrgtPos', 'Time', 'AOI'

df <- df %>%
    mutate(Subject = factor(Subject)) %>%
    mutate(Trial = scale(Trial)) %>%
    mutate(Condition = factor(Condition, levels = 
                c("complex", "simple", "unambiguous"))) %>%
    mutate(MsgType = factor(MsgType, levels = c("shape", "color"))) %>%
    mutate(TrgtPos = factor(TrgtPos, levels = c(1, 0, 2))) %>%
    mutate(AnswerTime = scale(AnswerTime)) %>%
    mutate(PropTimeOnSentMsg = scale(PropTimeOnSentMsg, scale = FALSE)) %>%
    mutate(PropTimeOnTrgt = scale(PropTimeOnTrgt, scale = FALSE)) %>%
    mutate(PropTimeOnDist = scale(PropTimeOnDist, scale = FALSE)) %>%
    mutate(PropTimeOnComp = scale(PropTimeOnComp, scale = FALSE)) %>%
    mutate(PropTimeOnAvailableMsgs = scale(PropTimeOnAvailableMsgs, scale = FALSE))

df_correct <- df %>%
  select(Subject, Trial, Condition, Correct, PropTimeOnComp,
         PropTimeOnSentMsg, PropTimeOnTrgt, PropTimeOnDist,
         PropTimeOnAvailableMsgs, PropTimeOnNonAOI, MsgType,
         TrgtPos, AnswerTime)

contrasts(df_correct$Condition) <- contr.helmert(3)
contrasts(df_correct$Condition)

contrasts(df_correct$MsgType) <- c(-1, 1)
contrasts(df_correct$MsgType)

contrasts(df_correct$TrgtPos) <- contr.treatment(3)
contrasts(df_correct$TrgtPos)

print(head(df_correct))

regression <- glm(
    Correct ~ Condition + TrgtPos + Trial +  PropTimeOnTrgt +
    PropTimeOnComp + PropTimeOnDist + PropTimeOnSentMsg + 
    PropTimeOnAvailableMsgs + MsgType + AnswerTime +
    Condition:PropTimeOnTrgt + Condition:PropTimeOnComp +
    Condition:PropTimeOnDist + Condition:PropTimeOnSentMsg +
    Condition:PropTimeOnAvailableMsgs + Condition:AnswerTime,
    # (1 | Subject),
    # specify dataset
    data = df_correct,
    # specify to fit a logistic regression
    family = binomial(link = "logit")
    # control = glmerControl(optCtrl=list(maxfun=100000))
)


print(summary(regression))

saveRDS(regression, file = paste0("analysis/regressions/per_trial/trained_models/cor_ans_regr_", format(Sys.time(), "%F_%R"), ".rds"))

emm = emmeans(regression, specs = pairwise ~ PropTimeOnTrgt|Condition, cov.reduce=range, trans='response')
print(emm$emmeans)
print(emm$contrasts)
emtr = emtrends(regression, specs = pairwise ~ Condition, var = 'PropTimeOnDist', trans='response')
print(emtr$emtrends)
print(emtr$contrasts)
print(emm)
emmip(regression, )
emmip(regression, Condition ~ PropTimeOnDist, cov.reduce = range, trans='response', 
    xlab = "Proportion of time on distractor", ylab = "Prediction") +
  theme(
    legend.text = element_text(size = 20),
    axis.title.x = element_text(size = 20),
    axis.title.y = element_text(size = 20),
    legend.title = element_text(size = 20)
  )
emmip(regression, PropTimeOnComp ~ Condition)
