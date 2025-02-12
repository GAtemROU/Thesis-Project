library(saccades)
library(tidyverse)

# load csv
load_path <- "~/uds/thesis/Thesis-Project/analysis/data/participants_raw_gaze/"
save_path <- "~/uds/thesis/Thesis-Project/analysis/data/participants_fixations/"
files <- list.files(path = load_path, pattern = "*.csv")
dfs <- files %>%
  map(function(x) {
    read.csv(paste0(load_path, x), header = TRUE)
  })

# detect fixations
participants_fixations <- dfs %>%
  map(function(x) {
    subset(detect.fixations(x, smooth.coordinates = TRUE, lambda = 1), event == "fixation")
  })

print(participants_fixations[[1]])
# plots
ggplot(participants_fixations[[1]], aes(x, y)) +
  geom_point(size = 0.2) +
  coord_fixed() +
  facet_wrap(~trial)

# save csv
mapply(function(df, file) {
  write.csv(df, file = paste0(save_path, file))
}, participants_fixations, files)
