library(GGally)
library(tidyverse)
library(scales)

bysubject <- read.csv("analysis/data/final_datasets/final_experiment_participants_extended.csv")

accuracybins <- bysubject %>%
  mutate(simple_bin = round(AnswerAccuracySimple, 1),
         complex_bin = round(AnswerAccuracyComplex, 1)) %>%
  group_by(simple_bin, complex_bin) %>%
  summarize(count = n())

binplot <- ggplot(accuracybins) +
  aes(x = simple_bin, y = complex_bin, size = count) +
  geom_hline(yintercept = .5, linewidth = .2) +
  geom_vline(xintercept = .5, linewidth = .2) +
  geom_point(shape = 19) +
  theme_bw() +
xlim(0, 1) + ylim(0, 1) +
scale_y_continuous(labels = scales::percent, breaks = seq(0, 1, by = 0.1)) +
  scale_x_continuous(labels = scales::percent, n.breaks = 10) +
  scale_y_continuous(labels = scales::percent, n.breaks = 10) +
  labs(x = "Proportion of target choices (simple)",
       y = "Proportion of target choices (complex)",
       size = "Number of\nparticipants",
       title = "By-participant performance")
binplot

ggsave("mdplot.png", width = 6, height = 4, units = "in", dpi = 800)
