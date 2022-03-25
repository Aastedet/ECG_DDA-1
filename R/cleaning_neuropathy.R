library(data.table)
library(here)

# Read in all the raw csv files in a list, although we only use the data from one of them (the survey data):
elderly_data_list <-
  lapply(list.files(here("raw_csv_data"), full.names = T), fread, stringsAsFactors = F)

# Extracting the survey data data.frame for readability:

survey <- elderly_data_list[[6]]

# There are 134 variables, most of them have horrible names:
names(survey)

# Find the diabetes variable and neuropathy:
names(survey)[grepl("DM",names(survey))] # "DM PATIENT MEDICAL HISTORY"
names(survey)[grepl("AUTO",names(survey))]
# "Dizziness AUTONOMIC SYMPTOMS"
# Numbness AUTONOMIC SYMPTOMS"
# "Painful feet AUTONOMIC SYMPTOMS"
# "Syncope AUTONOMIC SYMPTOMS"
# "OH AUTONOMIC SYMPTOMS"     

# The data contents don't correspond to the questions described in the NTSS paper.
              
# Filtering to only id, visit number, diabetes status and the two neuropathy variables on numbness and pain :
neuropathy_data <- survey[, c(1, 2, 32, 11:12)]

# Unfuck column names:

names(neuropathy_data) <- snakecase::to_snake_case(names(neuropathy_data))

# Recode string data to binary and NAs:

binary_converter_function <- function(x) {
  dplyr::case_when(
    x == "N/A" ~ NA,
    x == "YES" | x == "Yes" ~ TRUE,
    x == "NO" ~ FALSE
  )
}

mod_cols = names(neuropathy_data)[3:5]
neuropathy_data[ , (mod_cols) := lapply(.SD, binary_converter_function), .SDcols = mod_cols]

# Calculate NTSS score:
# We can't really calculate it exactly, as the dataset does not contain the symptoms described in the NTSS questionnaire
# And in the NTSS paper, each symptom is score with a severity component.
# The dataset only reports the presence of symptoms or not.

# We'll hack it up:
# neuropathy is the presence of either numbness or pain in the feet:

neuropathy_data[, neuropathy := apply(neuropathy_data[, 4:5], 1, function(x)
  sum(x)) >= 1]

# Recode the two partly missing data to NA's to no neuropathy:
neuropathy_data[is.na(neuropathy)]$neuropathy <- FALSE

# rename and and save dataset without excess variables:
names(neuropathy_data)[3] <- "diabetes"


fwrite(neuropathy_data[, c(1:3, 6)], file = here("output_data", "neuropathy.csv"))



