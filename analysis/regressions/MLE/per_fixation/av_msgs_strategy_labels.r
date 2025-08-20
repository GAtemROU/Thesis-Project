library(stats)
library(tidyverse)
library(lme4)
library(scales)

df <- read.csv("analysis/data/final_datasets/final_experiment_fixations.csv")

# 'Subject', 'Trial', 'Condition', 'MsgType', 'TrgtPos', 'Time', 'AOI'

df <- df %>%
    filter(Condition %in% c("complex", "simple")) %>%
    mutate(Subject = factor(Subject)) %>%
    mutate(Trial = scale(Trial)) %>%
    mutate(Condition = factor(Condition, levels = 
                c("complex", "simple"))) %>%
    mutate(MsgType = factor(MsgType, levels = c("shape", "color"))) %>%
    mutate(TrgtPos = factor(TrgtPos, levels = c(1, 0, 2))) %>%
    mutate(StrategyLabel = factor(StrategyLabel, levels = c(0, 1, 2)))

df_av_msgs <- df %>%
    mutate(OnAvMsgs = AOI == "av_msgs") %>%
    mutate(OnAvMsgs = OnAvMsgs*1) %>%
    select(Subject, Trial, Condition, MsgType, TrgtPos, StrategyLabel, Correct, OnAvMsgs)

contrasts(df_av_msgs$Condition) <- c(-1, 1)
contrasts(df_av_msgs$Condition)

contrasts(df_av_msgs$StrategyLabel) <- contr.helmert(3)
contrasts(df_av_msgs$StrategyLabel)

contrasts(df_av_msgs$MsgType) <- c(-1, 1)
contrasts(df_av_msgs$MsgType)

contrasts(df_av_msgs$TrgtPos) <- contr.treatment(3)
contrasts(df_av_msgs$TrgtPos)

# fitting logistic regression with an intercept plus 4 slopes,
# and associated random effects by subject
regression <- glmer(
    OnAvMsgs ~ Condition + TrgtPos + Trial +
    StrategyLabel + Correct + MsgType +
    Condition:StrategyLabel + (1| Subject),
    # specify dataset
    data = df_av_msgs,
    # specify to fit a logistic regression
    family = binomial(link = "logit"),
    verbose = TRUE
)

sink(file = "analysis/regressions/MLE/per_fixation/results/av_msgs_strategy_labels.txt")
print(summary(regression))
emmns = emmeans(regression, specs = pairwise ~ Condition : StrategyLabel)
print(emmns$emmeans)
print(emmns$contrasts)
sink()

# saveRDS(regression, file = paste0("/home/gatemrou/uds/thesis/Thesis-Project/analysis/regressions/per_correct_fixation/trained_models/av_msgs_regr_", format(Sys.time(), "%F_%R"), ".rds"))
emmip(regression, Condition ~ StrategyLabel, cov.reduce = range, 
  xlab = "Strategy Label", ylab = "Prediction") +
  theme(
  legend.key.size = unit(2, "lines"), # Increase the size of legend keys
  aspect.ratio = 1,
  legend.text = element_text(size = 20),
  axis.title.x = element_text(size = 20),
  axis.title.y = element_text(size = 20),
  legend.title = element_text(size = 20),
  axis.text = element_text(size = 16), # Increase text size next to ticks
  axis.ticks = element_line(size = 1.2) # Make tick lines wider
  )#
ggsave(
    filename = "analysis/regressions/MLE/per_fixation/results/av_msgs_strategy_labels_plot.png",
    plot = last_plot(),
    width = 8,
    height = 8,
    dpi = 300
)
