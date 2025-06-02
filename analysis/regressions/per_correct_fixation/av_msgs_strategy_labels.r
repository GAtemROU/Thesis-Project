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
    mutate(StrategyLabel = factor(StrategyLabel, levels = c(0, 1, 2))) %>% # check !!!
    mutate(TrgtPos = factor(TrgtPos, levels = c(1, 0, 2)))

df_av_msgs <- df %>%
    mutate(OnAvMsgs = AOI == "available_msgs") %>%
    select(Subject, Trial, Condition, MsgType, TrgtPos, StrategyLabel, Time, OnAvMsgs)

contrasts(df_av_msgs$Condition) <- contr.helmert(3)
contrasts(df_av_msgs$Condition)

contrasts(df_av_msgs$Condition) <- contr.helmert(3)
contrasts(df_av_msgs$Condition)

contrasts(df_av_msgs$MsgType) <- c(-1, 1)
contrasts(df_av_msgs$MsgType)

contrasts(df_av_msgs$TrgtPos) <- contr.treatment(3)
contrasts(df_av_msgs$TrgtPos)

print(head(df_av_msgs))

# fitting logistic regression with an intercept plus 4 slopes,
# and associated random effects by subject
regression <- glmer(
    OnAvMsgs ~ Condition + Trial + MsgType + TrgtPos + StrategyLabel +
        (1| Subject),
    # specify dataset
    data = df_av_msgs,
    # specify to fit a logistic regression
    family = binomial(link = "logit"),
    verbose = TRUE
)


print(summary(regression))

# saveRDS(regression, file = paste0("/home/gatemrou/uds/thesis/Thesis-Project/analysis/regressions/per_correct_fixation/trained_models/av_msgs_regr_", format(Sys.time(), "%F_%R"), ".rds"))
