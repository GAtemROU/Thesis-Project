library(stats)
library(tidyverse)
library(lme4)
library(scales)
library(emmeans)
library(magrittr)
library(glmnet)
library(broom)
library(gridExtra)
library(reshape2)
library(ggplot2)

set.seed(42)

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

fit <- glmnet(X_lasso, y_lasso,
    family = "binomial",
    alpha = 1)

print(fit)
# plot(fit)

cvfit <- cv.glmnet(X_lasso, y_lasso,
    family = "binomial",
    alpha = 1,
    foldid = as.numeric(df_correct$Subject),
    parallel = TRUE)

print(cvfit)
# plot(cvfit)

coef(cvfit, s = "lambda.min")
coef(cvfit, s = "lambda.1se")

# ---- Data for Plot A ----
cv_df <- data.frame(
  log_lambda = log(cvfit$lambda),
  RMSE = cvfit$cvm,
  se = cvfit$cvsd
)

# ---- Data for Plot B ----
coef_df <- as.data.frame(as.matrix(fit$beta))
coef_df$feature <- rownames(coef_df)
coef_long <- reshape2::melt(coef_df, id.vars = "feature", 
                            variable.name = "step", value.name = "coef")
coef_long$log_lambda <- rep(log(fit$lambda), each = nrow(fit$beta))

x_label_exp <- expression(paste("Regularization parameter: log(", lambda, " )"))

# ---- Plot A (no legend) ----
pA <- ggplot(cv_df, aes(x = log_lambda, y = RMSE)) +
  geom_errorbar(aes(ymin = RMSE - se, ymax = RMSE + se), width = 0.1) +
  geom_point(color = "red") +
  geom_line(color = "red") +
  geom_vline(xintercept = log(cvfit$lambda.min), linetype = "dotted", size = 1) +
  geom_vline(xintercept = log(cvfit$lambda.1se), linetype = "dotdash", size = 1) +
  labs(x = x_label_exp, y = "RMSE") +
  theme_minimal(base_size = 14) +
  theme(legend.position = "none")


# Identify coefficients at lambda.min
coef_at_min <- as.matrix(coef(fit, s = cvfit$lambda.min))
coef_at_min <- coef_at_min[-1, , drop = FALSE]  # drop intercept if present
rownames(coef_at_min) <- rownames(fit$beta)     # keep feature names

custom_colors <- c(
    "Condition1" = "blue",
    "TrgtPos2" = "green",
    "TrgtPos3" = "green",
    "Trial" = "green",
    "MsgType1" = "green",
    "PropTimeOnTrgt" = "orange",
    "PropTimeOnComp" = "orange",
    "PropTimeOnDist" = "orange",
    "PropTimeOnSentMsg" = "orange",
    "PropTimeOnAvailableMsgs" = "orange",
    "RateTogglingAvailableMsgs" = "orange",
    "AnswerTime" = "yellow",
    "Condition1:PropTimeOnTrgt" = "purple",
    "Condition1:PropTimeOnComp" = "purple",
    "Condition1:PropTimeOnDist" = "purple",
    "Condition1:PropTimeOnSentMsg" = "purple",
    "Condition1:PropTimeOnAvailableMsgs" = "purple",
    "Condition1:RateTogglingAvailableMsgs" = "purple",
    "Condition1:AnswerTime" = "purple"
)
names(is_zero_at_min) <- rownames(coef_at_min)

# All features
all_features <- unique(coef_long$feature)

# Create feat_colors ensuring every feature in all_features is named in feat_colors
feat_colors <- setNames(
  sapply(all_features, function(f) {
    if (is_zero_at_min[f]) {
      "grey70"
    } else if (f %in% names(custom_colors)) {
      custom_colors[f]
    } else {
      "black"  # fallback color
    }
  }),
  all_features
)

# Ensure coef_long$feature is a factor with levels matching names(feat_colors)
coef_long$feature <- factor(coef_long$feature, levels = all_features)


# ---- Plot B (with legend) ----
pB <- ggplot(coef_long, aes(x = log_lambda, y = coef, color = feature)) +
  geom_line(size = 1) +
  geom_vline(xintercept = log(cvfit$lambda.min), linetype = "dotted", size = 1) +
  geom_vline(xintercept = log(cvfit$lambda.1se), linetype = "dotdash", size = 1) +
  labs(x = x_label_exp, y = "Model estimate") +
  scale_color_manual(values = feat_colors) +
  theme_minimal(base_size = 14) +
  theme(
    legend.position = "right",
    legend.text = element_text(size = 14),
    legend.key.size = unit(1.2, "cm"),      # size of color boxes (keep or adjust)
    legend.key.height = unit(0.6, "cm"),    # reduce height of each legend key
    legend.spacing.y = unit(0.4, "cm")      # reduce space between legend items vertically
  )
# ---- Extract legend ----

# Helper to extract legend
g_legend <- function(a.gplot){
  tmp <- ggplotGrob(a.gplot)
  leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
  tmp$grobs[[leg]]
}

shared_legend <- g_legend(pB)

# Remove legend from B
pB <- pB + theme(legend.position = "none")

# ---- Arrange with shared legend ----
full_plot <- gridExtra::grid.arrange(
  gridExtra::arrangeGrob(pA, pB, ncol = 1, heights = c(1, 1)),
  shared_legend,
  ncol = 2,
  widths = c(1, 1.5) # adjust as needed
)

# Save the plot
ggsave("analysis/regressions/MLE/per_trial/lasso_plots/lasso_plot_correct.png",
       full_plot, width = 12, height = 8, units = "in", dpi = 300)
