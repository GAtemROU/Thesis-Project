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
plot(fit)

cvfit <- cv.glmnet(X_lasso, y_lasso,
    family = "binomial",
    alpha = 1,
    foldid = as.numeric(df_correct$Subject),
    parallel = TRUE)

print(cvfit)
plot(cvfit)

coef(cvfit, s = "lambda.min")
coef(cvfit, s = "lambda.1se")

# # Assuming your CV object is called `cvfit`
# # Convert from MSE to RMSE
# rmse <- sqrt(cvfit$cvm)
# rmse_se <- cvfit$cvsd

# plot(log(cvfit$lambda), rmse, 
#      ylim = range(rmse - rmse_se, rmse + rmse_se), 
#      pch = 20, col = "red",
#      xlab = "Regularization parameter: log(λ)", 
#      ylab = "RMSE")

# # Error bars
# segments(log(cvfit$lambda), rmse - rmse_se, 
#          log(cvfit$lambda), rmse + rmse_se, col = "black")

# # Vertical lines for λ_min and λ_1se
# abline(v = log(cvfit$lambda.min), lty = 2)   # min RMSE
# abline(v = log(cvfit$lambda.1se), lty = 4)   # 1-SE rule

# coef_mat <- as.matrix(fit$beta)  # p x length(lambda)
# lambdas <- fit$lambda
# feature_names <- rownames(coef_mat)

# # Determine which features are cut
# cut_features <- apply(coef_mat, 1, function(coefs) all(coefs == 0))

# # -------------------------
# # Define grouping → colors
# # -------------------------
# group_colors <- c(
#     "Condition" = "blue",
#     "TrgtPos" = "green",
#     "Trial" = "green",
#     "MsgType" = "green",
#     "PropTimeOnTrgt" = "orange",
#     "PropTimeOnComp" = "orange",
#     "PropTimeOnDist" = "orange",
#     "PropTimeOnSentMsg" = "orange",
#     "PropTimeOnAvailableMsgs" = "orange",
#     "RateTogglingAvailableMsgs" = "orange",
#     "AnswerTime" = "yellow",
#     "Condition:PropTimeOnTrgt" = "purple",
#     "Condition:PropTimeOnComp" = "purple",
#     "Condition:PropTimeOnDist" = "purple",
#     "Condition:PropTimeOnSentMsg" = "purple",
#     "Condition:PropTimeOnAvailableMsgs" = "purple",
#     "Condition:RateTogglingAvailableMsgs" = "purple",
#     "Condition:AnswerTime" = "purple"
# )

# # Default grey for cut features
# feature_colors <- rep("grey", length(feature_names))

# # Assign colors based on group mapping
# for (name in names(group_colors)) {
#   feature_colors[grepl(name, feature_names)] <- group_colors[name]
# }

# # -------------------------
# # Plot settings
# # -------------------------
# # Create layout: 2 columns, first for plot, second for legend
# layout(matrix(c(1,2), nrow = 1), widths = c(3, 1))

# ## ---- Panel 1: LASSO coefficient paths ----
# par(mar = c(5, 5, 2, 1))  # normal margins for plot
# plot(range(xvals), range(coef_mat), type = "n",
#      xlab = "Regularization parameter: log(λ)",
#      ylab = "Model estimate")

# for (i in seq_len(nrow(coef_mat))) {
#   lines(xvals, coef_mat[i, ], col = feature_colors[i], lwd = 1.5)
# }

# # λ lines stay inside plot now
# abline(v = log(cvfit$lambda.min), lty = 2)
# abline(v = log(cvfit$lambda.1se), lty = 4)

# ## ---- Panel 2: Legend only ----
# par(mar = c(5, 0, 2, 2))  # minimal margins
# plot.new()                # empty plot area
# legend("center",
#        legend = unique(feature_names[feature_colors != "grey"]),
#        col = unique(feature_colors[feature_colors != "grey"]),
#        lwd = 1.5, cex = 0.8, bty = "n")


cv_df <- data.frame(
  log_lambda = log(cvfit$lambda),
  RMSE = cvfit$cvm,
  se = cvfit$cvsd
)

# ---- Prepare coefficient paths ----
coef_df <- as.data.frame(as.matrix(fit$beta))
coef_df$feature <- rownames(coef_df)
coef_long <- melt(coef_df, id.vars = "feature", variable.name = "step", value.name = "coef")
coef_long$log_lambda <- rep(log(fit$lambda), each = nrow(fit$beta))

# ---- Assign colors ----
colors <- RColorBrewer::brewer.pal(8, "Dark2")
feat_colors <- setNames(rep(colors, length.out = length(unique(coef_long$feature))),
                        unique(coef_long$feature))

# ---- Plot A (no legend) ----
pA <- ggplot(cv_df, aes(x = log_lambda, y = RMSE)) +
  geom_errorbar(aes(ymin = RMSE - se, ymax = RMSE + se), width = 0.1) +
  geom_point(color = "red") +
  geom_line(color = "red") +
  geom_vline(xintercept = log(cvfit$lambda.min), linetype = "dotted", size = 1) +
  geom_vline(xintercept = log(cvfit$lambda.1se), linetype = "dotdash", size = 1) +
  labs(x = "Regularization parameter: log(λ)", y = "RMSE") +
  theme_minimal(base_size = 14) +
  theme(legend.position = "none")  # Remove legend

# ---- Plot B (legend only here) ----
pB <- ggplot(coef_long, aes(x = log_lambda, y = coef, color = feature)) +
  geom_line(size = 1) +
  geom_vline(xintercept = log(cvfit$lambda.min), linetype = "dotted", size = 1) +
  geom_vline(xintercept = log(cvfit$lambda.1se), linetype = "dotdash", size = 1) +
  labs(x = "Regularization parameter: log(λ)", y = "Model estimate") +
  scale_color_manual(values = feat_colors) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "right")


# ---- Combine panels ----
grid.arrange(pA, pB, ncol = 1, heights=c(1, 1))


