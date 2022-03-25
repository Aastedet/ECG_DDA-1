library(readr)
library(here)

# Read in all the raw csv files in a list, although we only use the data from one of them (the survey data):
elderly_data_list <- lapply(list.files(here("raw_csv_data"), full.names = T), read_csv)

# Extracting the survey data data.frame for readability:

survey <- elderly_data_list[[6]]

# There are 134 variables, most of them have horrible names:
names(survey)

# Filtering to only id, visit number and the six neuropathy questions:
neuropathy_data <- survey[, c(1, 2, 10:14)]
