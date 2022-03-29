

# 1. Load required packages and read csv files. ----------------------------------------------


library(dplyr)
library(data.table)
library(here)
library(snakecase)


# Read in all the raw csv files in a list:
elderly_data_list <-
  lapply(list.files(here("raw_csv_data"), full.names = T), fread, stringsAsFactors = F)



# 2. Overview of the contents of csv files ---------------------------------


# Overview of the 10 files and contents:
list.files(here("raw_csv_data"), full.names = F)


## elderly_data_list[[1]]: "GE-79_Data_Dictionary.csv":
# A dictionary detailing what each variable means, with examples of data from two subjects: S0434 & S0078

## elderly_data_list[[2]]: "GE-79_Files_and_Channels.csv":
# is an overview of what is done at each visit and where the data goes
# (well, it tries to provide an overview, but doesn't really help)

## elderly_data_list[[3]]: "GE-79_Files_per_subject.csv":
# Is a list of how much lab and ECG data is available for each individual

## elderly_data_list[[4]]: "GE-79_Summary_Table-Cognitive-Testing.csv"
# Is cognitive test results

## elderly_data_list[[5]]: "GE-79_Summary_Table-Demographics-MRI-Part1.csv"
# Is MR data, with a little extra data on group, race, BMI, and a little medical history

## elderly_data_list[[6]]: "GE-79_Summary_Table-Labs-BP-Ophthalmogic-Walk.csv"
# Is survey data, medication history, lab biomarkers, blood pressure, eye examination and gait test.

## elderly_data_list[[7:9]]: "GE-79_Summary_Table-MRI-Part[2-4].csv"
# These 3 files are all pure MR-cerebrum data

## elderly_data_list[[10]]: "GE-79_Summary_Table-MRI-Part5-History.csv"
# Is also MR-cerebrum data, but appears to hold some survey/medical history data as well


# The data in 10 appears to be a duplicate of 6, as the survey data in # 10 is the exact same data as #6):
identical(
  elderly_data_list[[6]]$`Numbness AUTONOMIC SYMPTOMS`,
  elderly_data_list[[10]]$`Numbness AUTONOMIC SYMPTOMS`
) # TRUE




# 3. Extract and clean the survey data ----------------------------------------------

# Data from "GE-79_Summary_Table-Labs-BP-Ophthalmogic-Walk.csv" for further analysis:
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

# The data contents don't correspond to the questions described in the NTSS paper:
# https://trello.com/c/Y5ur0j0R
              
# Filtering to only id, visit number, diabetes status and the two neuropathy variables on numbness and pain :
neuropathy_data <- survey[, c(1, 2, 32, 11:12)]

# Unfuck column names:

names(neuropathy_data) <- to_snake_case(names(neuropathy_data))

# Recode string data to binary and NAs:

binary_converter_function <- function(x) {
  case_when(
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

# We'll create a simpler variable instead, which should be useful:
# neuropathy is defined as the presence of either numbness or pain in the feet:

neuropathy_data[, neuropathy := apply(neuropathy_data[, 4:5], 1, function(x)
  sum(x)) >= 1]

# Recode the two partly missing data to NA's to no neuropathy:
neuropathy_data[is.na(neuropathy)]$neuropathy <- FALSE

# rename and and save dataset without excess variables, on file for each visit, where neuropathy was recorded:
names(neuropathy_data)[3] <- "diabetes"

neuropathy_data_visit2 <- neuropathy_data[visit == 2, c(1:3, 6)]
neuropathy_data_visit8 <- neuropathy_data[visit == 8, c(1:3, 6)]




# 4. Inspect and summarize data -------------------------------------------


## Create a list of individuals with ECG data available
# according to elderly_data_list[[3]] ("GE-79_Files_per_subject.csv"),
# in order to cross-examine how many have ECG data available:
ecg_available <- elderly_data_list[[3]]
names(ecg_available) <- to_snake_case(names(ecg_available))


# Summary of available data:

# 77 patients (44 with diabetes) participated in the baseline screening (visit 2):
summary(neuropathy_data_visit2)

# 42 of these have ECGs available (22 with diabetes):
summary(neuropathy_data_visit2[patient_id %in% ecg_available[ecg == 1]$subject_id])

# Apparently, 71 individuals had ECGS taken,
# but 29 of these are unavailable due to data formatting issues with the ECGs (WTF?):
summary(neuropathy_data_visit2[patient_id %in% ecg_available[ecg != 0]$subject_id])

# Out of the 22 individuals with diabetes and a proper ECG, 7 had neuropathy symptoms:
summary(neuropathy_data_visit2[diabetes == T & patient_id %in% ecg_available[ecg == 1]$subject_id])




## This is probably not relevant to us, but there was also considerable loss-to-follow-up:

# Only 44 of the 77 baseline patients participated in the follow-up screening (visit 8):
summary(neuropathy_data_visit8)
# And only 23 of those attending follow-up have a proper ECG available:
summary(neuropathy_data_visit8[patient_id %in% ecg_available[ecg == 1]$subject_id])


# And very few develop neuropathy between visit 2 and visit 8 (only 6 individuals, 3 with diabetes):
summary(neuropathy_data_visit2[patient_id %in% ecg_available[ecg == 1]$subject_id &
                                 neuropathy == F &
                                 patient_id %in% neuropathy_data_visit8[neuropathy == T]$patient_id])


# 5. Save the clean neuropathy data sets ----------------------------------


# I save both datasets, although we may only end up working with the baseline visit.

# The full data set is saved,
# in the hope that we're able to use more ECG data than what is described as available in the csv
# (e.g. maybe we have appropriately formatted data from the 10 second ECGs from visit 1,
# or from 24 hour ECGs performed at the follow-up visit)

fwrite(neuropathy_data_visit2, file = here("output_data", "neuropathy_visit_2.csv"))
fwrite(neuropathy_data_visit8, file = here("output_data", "neuropathy_visit_8.csv"))



