library(stats)
library(tidyverse)
library(lme4)

df <- read.csv("~/uds/thesis/Thesis-Project/analysis/data/gaze.csv")
# 'Subject', 'Trial', 'Condition', 'MsgType', 'TrgtPos', 'Time', 'AOI'

df <- df %>%
    mutate(Subject = factor(Subject)) %>%
    mutate(Trial.c = Trial - 7) %>%
    mutate(Condition = factor(Condition, levels = c("complex", "simple", "unambiguous"))) %>%
    mutate(MsgType = factor(MsgType, levels = c("shape", "color"))) %>%
    mutate(TrgtPos = factor(TrgtPos, levels = c(1, 0, 2)))

df_av_msgs <- df %>%
    mutate(OnAvMsgs = AOI == "available_msgs") %>%
    select(Subject, Trial.c, Condition, MsgType, TrgtPos, Time, OnAvMsgs)

contrasts(df_av_msgs$Condition) <- contr.helmert(3)
contrasts(df_av_msgs$Condition)

contrasts(df_av_msgs$MsgType) <- c(-1, 1)
contrasts(df_av_msgs$MsgType)

contrasts(df_av_msgs$TrgtPos) <- contr.treatment(3)
contrasts(df_av_msgs$TrgtPos)

print(head(df_av_msgs))



# fitting logistic regression with an intercept plus 4 slopes,
# and associated random effects by subject
regression1a <- glmer(
    OnAvMsgs ~ Condition + Trial.c + MsgType + TrgtPos +
        (1 + Condition + Trial.c + MsgType + TrgtPos | Subject),
    # specify dataset
    data = df_av_msgs,
    # specify to fit a logistic regression
    family = binomial(link = "logit"),
    verbose = TRUE
)

print(summary(regression1a))



# output:
# Generalized linear mixed model fit by maximum likelihood (Laplace
#   Approximation) [glmerMod]
#  Family: binomial  ( logit )
# Formula: OnAvMsgs ~ Condition + Trial.c + MsgType + TrgtPos + (1 + Condition +
#     Trial.c + MsgType + TrgtPos | Subject)
#    Data: df_av_msgs

#      AIC      BIC   logLik deviance df.resid
#   4653.2   4885.8  -2291.6   4583.2     5641

# Scaled residuals:
#     Min      1Q  Median      3Q     Max
# -0.7044 -0.4971 -0.3712 -0.1589  6.8022

# Random effects:
#  Groups  Name        Variance Std.Dev. Corr
#  Subject (Intercept) 1.415845 1.18989
#          Condition1  0.365399 0.60448  -0.83
#          Condition2  0.157956 0.39744   0.01 -0.20
#          Trial.c     0.007624 0.08732  -0.02  0.08 -0.97
#          MsgType1    0.375466 0.61275  -0.88  0.83  0.35 -0.40
#          TrgtPos2    2.737096 1.65442  -0.87  0.73 -0.47  0.51  0.55
#          TrgtPos3    2.935094 1.71321  -0.94  0.68 -0.19  0.27  0.67  0.95
# Number of obs: 5676, groups:  Subject, 4

# Fixed effects:
#             Estimate Std. Error z value Pr(>|z|)
# (Intercept) -1.45061    0.65794  -2.205   0.0275 *
# Condition1  -0.24183    0.34347  -0.704   0.4814
# Condition2  -0.20446    0.21737  -0.941   0.3469
# Trial.c     -0.03684    0.05177  -0.712   0.4767
# MsgType1    -0.00322    0.31500  -0.010   0.9918
# TrgtPos2    -0.96543    0.91304  -1.057   0.2903
# TrgtPos3    -0.73116    0.93227  -0.784   0.4329
# ---
# Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

# Correlation of Fixed Effects:
#            (Intr) Cndtn1 Cndtn2 Tril.c MsgTy1 TrgtP2
# Condition1 -0.790
# Condition2  0.091 -0.273
# Trial.c     0.012 -0.011 -0.656
# MsgType1   -0.784  0.697  0.349 -0.291
# TrgtPos2   -0.879  0.704 -0.468  0.423  0.499
# TrgtPos3   -0.933  0.667 -0.204  0.253  0.622  0.945
# optimizer (Nelder_Mead) convergence code: 4 (failure to converge in 10000 evaluations)
# Model failed to converge with max|grad| = 0.446179 (tol = 0.002, component 1)
# failure to converge in 10000 evaluations

# Warning messages:
# 1: In optwrap(optimizer, devfun, start, rho$lower, control = control,  :
#   convergence code 1 from bobyqa: bobyqa -- maximum number of function evaluations exceeded
# 2: In (function (fn, par, lower = rep.int(-Inf, n), upper = rep.int(Inf,  :
#   failure to converge in 10000 evaluations
# 3: In optwrap(optimizer, devfun, start, rho$lower, control = control,  :
#   convergence code 4 from Nelder_Mead: failure to converge in 10000 evaluations
# 4: In checkConv(attr(opt, "derivs"), opt$par, ctrl = control$checkConv,  :
#   Model failed to converge with max|grad| = 0.446179 (tol = 0.002, component 1)
