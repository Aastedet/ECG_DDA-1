

# 1. Load required packages and read csv files. ----------------------------------------------


library(dplyr)
library(data.table)
library(here)
library(snakecase)



# 2. Load raw csv files ------------------------------------------------------


# From "Cerebromicrovascular Disease in Elderly with Diabetes" ("GE-79"):
# https://physionet.org/content/cded/1.0.0/
cded_data <-
  lapply(list.files(here("raw_csv_data", "GE-79"), full.names = T), fread, stringsAsFactors = F)

# From "Cerebral perfusion and cognitive decline in type 2 diabetes" ("GE-75"):
# https://physionet.org/content/cerebral-perfusion-diabetes/1.0.0/
cpd_data <-
  lapply(list.files(here("raw_csv_data", "GE-75"), full.names = T), fread, stringsAsFactors = F)

# From: "Cerebral Vasoregulation in Elderly with Stroke" ("GE-72"):
# https://www.physionet.org/content/cves/1.0.0/
cves_data <-
  fread(list.files(here("raw_csv_data", "GE-72"), full.names = T), stringsAsFactors = F)

# From "Cerebral Vasoregulation in Diabetes" ("GE-71"):
# https://physionet.org/content/cerebral-vasoreg-diabetes/1.0.0/
cvd_data <-
  lapply(list.files(here("raw_csv_data", "GE-71"), full.names = T), fread, stringsAsFactors = F)



# 3. Estimate combined population size -------------------------------------------


# Unique subjects:
# Total: 391
length(unique(toupper(
  c(
    cded_data[[3]]$`Subject ID`,
    # 82: length(unique(cded_data[[3]]$`Subject ID`))
    cpd_data[[4]]$`Subject ID`,
    # 88: length(unique(cpd_data[[4]]$`Subject ID`))
    cves_data$subject_number,
    # 172: length(unique(cves_data$subject_number))
    cvd_data[[4]]$`Subject ID`
    # 86: length(unique(cvd_data[[4]]$`Subject ID`))
  )
)))

# With ECG data available: 220
length(unique(toupper(
  c(
    cded_data[[3]][ECG == 1]$`Subject ID`,
    # 47: length(unique(cded_data[[3]][ECG == 1]$`Subject ID`))
    
    cpd_data[[4]][ECG == 1]$`Subject ID`,
    # 51: length(unique(cpd_data[[4]][ECG == 1]$`Subject ID`))
    
    cves_data[completed_visit_status == "COMPLETED"]$subject_number,
    # 91: length(unique(cves_data[completed_visit_status == "COMPLETED"]$subject_number))
    
    cvd_data[[4]][`Head Up Tilt D2` == 1]$`Subject ID`
    # 57: length(unique(cvd_data[[4]][`Head Up Tilt D2` == 1]$`Subject ID`))
  )
)))


# Individuals with diabetes, and ECG data available: 90
length(unique(toupper(
  c(
    cded_data[[3]][ECG == 1 & toupper(`Subject ID`) %in% toupper(cded_data[[6]][`DM PATIENT MEDICAL HISTORY` == "YES"]$`patient ID`)]$`Subject ID`,
    # 22: length(unique(cded_data[[3]][ECG == 1 & `Subject ID` %in% cded_data[[6]][`DM PATIENT MEDICAL HISTORY` == "YES"]$`patient ID`]$`Subject ID`))
    
    cpd_data[[4]][ECG == 1 & Group == "DM"]$`Subject ID`,
    # 45: length(unique(cpd_data[[4]][ECG == 1 & Group == "DM"]$`Subject ID`))
    
    cves_data[completed_visit_status == "COMPLETED" & `DM PATIENT MEDICAL HISTORY` %in% c("yes", "YES")]$subject_number,
    # 2: length(unique(cves_data[completed_visit_status == "COMPLETED" & `DM PATIENT MEDICAL HISTORY` %in% c("yes", "YES")]$subject_number))
    
    cvd_data[[4]][`Head Up Tilt D2` == 1 & Group %in% c("DM", "DMOH")]$`Subject ID`
    # 29: length(unique(cvd_data[[4]][`Head Up Tilt D2` == 1 & Group %in% c("DM", "DMOH")]$`Subject ID`))
  )
)))



## 3.1. Overlap in subjects with diabetes and ECGs between the datasets --------------------------------

# Mainly between cded and cpd

### Overlap between cded and cpd/cves/cvd:

# cded vs cpd: 7: ("S0296" "S0301" "S0308" "S0314" "S0318" "S0372" "S0430"):
cded_data[[3]][ECG == 1 &
                 toupper(`Subject ID`) %in% toupper(cded_data[[6]][`DM PATIENT MEDICAL HISTORY` == "YES"]$`patient ID`) &
                 toupper(`Subject ID`) %in% toupper(cpd_data[[4]][ECG == 1 &
                                                                    Group == "DM"]$`Subject ID`)]

# cded vs. cves: 0:
nrow(cded_data[[3]][ECG == 1 &
                      toupper(`Subject ID`) %in% toupper(cded_data[[6]][`DM PATIENT MEDICAL HISTORY` == "YES"]$`patient ID`) &
                      toupper(`Subject ID`) %in% toupper(cves_data[completed_visit_status == "COMPLETED" &
                                                                     `DM PATIENT MEDICAL HISTORY` %in% c("yes", "YES")]$subject_number)])

# cded vs. cvd: 1 ("S0105"):
cded_data[[3]][ECG == 1 &
                      toupper(`Subject ID`) %in% toupper(cded_data[[6]][`DM PATIENT MEDICAL HISTORY` == "YES"]$`patient ID`) &
                      toupper(`Subject ID`) %in% toupper(cvd_data[[4]][`Head Up Tilt D2` == 1 & Group %in% c("DM", "DMOH")]$`Subject ID`)]


### No overlap between cpd and cves/cvd

# cpd vs. cves: 0:
nrow(cpd_data[[4]][ECG == 1 &
                     Group == "DM" &
                     toupper(`Subject ID`) %in% toupper(cves_data[completed_visit_status == "COMPLETED" &
                                                                    `DM PATIENT MEDICAL HISTORY` %in% c("yes", "YES")]$subject_number)])

# cpd vs. cvd: 0
nrow(cpd_data[[4]][ECG == 1 &
                     Group == "DM" &
                     toupper(`Subject ID`) %in% toupper(cvd_data[[4]][`Head Up Tilt D2` == 1 &
                                                                         Group %in% c("DM", "DMOH")]$`Subject ID`)])

### No 0verlap between cves and cvd: 0
nrow(cves_data[completed_visit_status == "COMPLETED" &
                 `DM PATIENT MEDICAL HISTORY` %in% c("yes", "YES") &
                 toupper(subject_number) %in% toupper(cvd_data[[4]][`Head Up Tilt D2` == 1 & Group %in% c("DM", "DMOH")]$`Subject ID`)])



# 2. Overview of the contents of csv files ---------------------------------



## 2.1. Overview of the cded files: -------------------------


list.files(here("raw_csv_data", "GE-79"), full.names = F)


## cded_data[[1]]: "GE-79_Data_Dictionary.csv":
# A dictionary detailing what each variable means, with examples of data from two subjects: S0434 & S0078

## cded_data[[2]]: "GE-79_Files_and_Channels.csv":
# is an overview of what is done at each visit and where the data goes
# (well, it tries to provide an overview, but doesn't really help)

## cded_data[[3]]: "GE-79_Files_per_subject.csv":
# Is a list of how much lab and ECG data is available for each individual

## cded_data[[4]]: "GE-79_Summary_Table-Cognitive-Testing.csv"
# Is cognitive test results

## cded_data[[5]]: "GE-79_Summary_Table-Demographics-MRI-Part1.csv"
# Is MR data, with a little extra data on group, race, BMI, and a little medical history

## cded_data[[6]]: "GE-79_Summary_Table-Labs-BP-Ophthalmogic-Walk.csv"
# Is survey data, medication history, lab biomarkers, blood pressure, eye examination and gait test.

## cded_data[[7:9]]: "GE-79_Summary_Table-MRI-Part[2-4].csv"
# These 3 files are all pure MR-cerebrum data

## cded_data[[10]]: "GE-79_Summary_Table-MRI-Part5-History.csv"
# Is also MR-cerebrum data, but appears to hold some survey/medical history data as well


# The data in 10 appears to be a duplicate of 6, as the survey data in # 10 is the exact same data as #6):
identical(
  cded_data[[6]]$`Numbness AUTONOMIC SYMPTOMS`,
  cded_data[[10]]$`Numbness AUTONOMIC SYMPTOMS`
) # TRUE


## 2.2 - 2.4 For later: Overview of the cpd/cves/cvd files: -------------------------

# cpd:
list.files(here("raw_csv_data", "GE-75"), full.names = F)

# cves:
list.files(here("raw_csv_data", "GE-72"), full.names = F)

# cvd:
list.files(here("raw_csv_data", "GE-71"), full.names = F)

# 3 Extract and clean the survey data ----------------------------------------------


# # 3.1: Clean cded data --------------------------------------------------------

# Survey data from "GE-79_Summary_Table-Labs-BP-Ophthalmogic-Walk.csv" for further analysis:

# There are 134 variables, most of them have horrible names:
names(cded_data[[6]])

# Find the diabetes variable and neuropathy:
names(cded_data[[6]])[grepl("DM",names(cded_data[[6]]))] # "DM PATIENT MEDICAL HISTORY"
names(cded_data[[6]])[grepl("AUTO",names(cded_data[[6]]))]
# "Dizziness AUTONOMIC SYMPTOMS"
# Numbness AUTONOMIC SYMPTOMS"
# "Painful feet AUTONOMIC SYMPTOMS"
# "Syncope AUTONOMIC SYMPTOMS"
# "OH AUTONOMIC SYMPTOMS"     

# The data contents don't correspond to the questions described in the NTSS paper:
# https://trello.com/c/Y5ur0j0R

# Make column names prettier for future use and clean case inconsistency in ID variable:
names(cded_data[[6]]) <- to_snake_case(names(cded_data[[6]]))
cded_data[[6]]$patient_id <-  toupper(cded_data[[6]]$patient_id)

# Filtering to only id, visit number, diabetes status and the two neuropathy variables on numbness and pain :
cded_survey <-
  cded_data[[6]][, .(
    patient_id,
    visit,
    dm_patient_medical_history,
    numbness_autonomic_symptoms,
    painful_feet_autonomic_symptoms
  )]



# Recode string data to binary and NAs:
binary_converter_function <- function(x) {
  case_when(
    x == "N/A" ~ NA,
    x == "YES" | x == "yes" | x == "Yes" ~ TRUE,
    x == "NO" | x == "no" | x == "No" ~ FALSE
  )
}

# Select columns to be modified
mod_cols = names(cded_survey)[3:5]
cded_survey[ , (mod_cols) := lapply(.SD, binary_converter_function), .SDcols = mod_cols]

# Calculate NTSS score:
# We can't really calculate it exactly, as the dataset does not contain the symptoms described in the NTSS questionnaire
# And in the NTSS paper, each symptom is score with a severity component.
# The dataset only reports the presence of symptoms or not.

# We'll create a simpler variable instead, which should be useful:
# neuropathy is defined as the presence of either numbness or pain in the feet:
# The few cases of missing data in a symptom variable is treated as no symptom of this kind.

cded_survey[, neuropathy_outcome := apply(cded_survey[, 4:5], 1, function(x)
  sum(x, na.rm = T)) >= 1]

# Set individuals with completely missing data to NA:
cded_survey[, no_neuropathy_data := apply(cded_survey[, 4:5], 1, function(x)
  sum(is.na(x))) == 2]

cded_survey[, neuropathy_outcome := fifelse(no_neuropathy_data == T, NA, neuropathy_outcome)]


# rename diabetes variable for convenience:
names(cded_survey)[3] <- "diabetes"

# Add variable to keep track of which dataset overlapping individuals came from:
cded_survey[, dataset := "cded"]

# rename and and save dataset without excess variables, on file for each visit, where neuropathy was recorded:
cded_visit2_clean <- cded_survey[visit == 2 & !is.na(diabetes) & !is.na(neuropathy_outcome), c(1, 3, 6, 8)]
cded_visit8_clean <- cded_survey[visit == 8 & !is.na(diabetes) & !is.na(neuropathy_outcome), c(1, 3, 6, 8)]


# # 3.2: Clean cpd data --------------------------------------------------------

# Questionnaire/symptoms only reported once, so no visit variable.
# Contains 3 neuropathy markers/variables,

names(cpd_data[[2]])

# Diabetes variable:
names(cpd_data[[2]])[grepl("DM",names(cpd_data[[2]]))]
# "DM PATIENT MEDICAL HISTORY"
# ("DM/Non-DM/Stroke"-variable is discarded, see mismatch: cpd_data[[2]][`patient ID` == "s0437", c(1, 3, 5, 980)])

# Neuropathy variables:
names(cpd_data[[2]])[grepl("AUTO",names(cpd_data[[2]]))]
# "Neuropathy AUTONOMIC SYMPTOMS"
# "Dizziness AUTONOMIC SYMPTOMS"
# "Numbness AUTONOMIC SYMPTOMS"    
# "Painful feet AUTONOMIC SYMPTOMS"
# "Syncope AUTONOMIC SYMPTOMS"
# "OH AUTONOMIC SYMPTOMS" 


# Clean column names and subject ID's:
names(cpd_data[[2]]) <- to_snake_case(names(cpd_data[[2]]))
cpd_data[[2]]$patient_id <- toupper(cpd_data[[2]]$patient_id)

# Filtering to only id, diabetes status and the three neuropathy variables on numbness and pain :
cpd_data <-
  cpd_data[[2]][, .(
    patient_id,
    dm_patient_medical_history,
    neuropathy_autonomic_symptoms,
    numbness_autonomic_symptoms,
    painful_feet_autonomic_symptoms
  )]



# Recode string data to binary and NAs:

mod_cols = names(cpd_data)[2:5]
cpd_data[ , (mod_cols) := lapply(.SD, binary_converter_function), .SDcols = mod_cols]

# Create the simpler neuropathy outcome variable:
# neuropathy is defined as the presence of either neuropathy, or numbness or pain in the feet:

cpd_data[, neuropathy_outcome := apply(cpd_data[, 3:5], 1, function(x)
  sum(x, na.rm = T)) >= 1]

# Set individuals with completely missing data to NA:
cpd_data[, no_neuropathy_data := apply(cpd_data[, 3:5], 1, function(x)
  sum(is.na(x))) == 3]

cpd_data[, neuropathy_outcome := fifelse(no_neuropathy_data == T, NA, neuropathy_outcome)]


# rename diabetes variable for convenience:
names(cpd_data)[2] <- "diabetes"


# Output:
cpd_data[, dataset := "cpd"]
cpd_clean <- cpd_data[!is.na(diabetes) & !is.na(neuropathy_outcome), c(1, 2, 6, 8)]


# # 3.3: Clean cves data --------------------------------------------------------

# Diabetes variable:
names(cves_data)[grepl("DM",names(cves_data))]
# "DM PATIENT MEDICAL HISTORY"
# ("DM/Non-DM/Stroke"-variable hold no DM category here,
# but the Non-DM group is used to add missing data in this dataset)

# Neuropathy variables:
names(cves_data)[grepl("AUTO",names(cves_data))]
# "Neuropathy AUTONOMIC SYMPTOMS"
# "Dizziness AUTONOMIC SYMPTOMS"
# "Numbness AUTONOMIC SYMPTOMS"    
# "Painful feet AUTONOMIC SYMPTOMS"
# "Syncope AUTONOMIC SYMPTOMS"
# "OH AUTONOMIC SYMPTOMS" 


# Clean column names and subject ID's:
names(cves_data) <- to_snake_case(names(cves_data))
cves_data$patient_id <- toupper(cves_data$subject_number)

# Filtering to only id, diabetes status and the three neuropathy variables on numbness and pain :
cves_survey <-
  cves_data[, .(
    patient_id,
    dm_non_dm_stroke,
    dm_patient_medical_history,
    neuropathy_autonomic_symptoms,
    numbness_autonomic_symptoms,
    painful_feet_autonomic_symptoms
  )]



# Recode string data to binary and NAs:

mod_cols = names(cves_survey)[3:6]
cves_survey[ , (mod_cols) := lapply(.SD, binary_converter_function), .SDcols = mod_cols]

# Create the simpler neuropathy outcome variable:
# neuropathy is defined as the presence of either neuropathy, or numbness or pain in the feet:

cves_survey[, neuropathy_outcome := apply(cves_survey[, 4:6], 1, function(x)
  sum(x, na.rm = T)) >= 1]

# Set individuals with completely missing data to NA:
cves_survey[, no_neuropathy_data := apply(cves_survey[, 4:6], 1, function(x)
  sum(is.na(x))) == 3]

cves_survey[, neuropathy_outcome := fifelse(no_neuropathy_data == T, NA, neuropathy_outcome)]


# Add missing data and rename diabetes variable for convenience:
cves_survey[, diabetes := fifelse(
  is.na(dm_patient_medical_history) & dm_non_dm_stroke == "Non-DM",
  FALSE,
  dm_patient_medical_history
)]


# Output:
cves_survey[, dataset := "cves"]
cves_clean <- cves_survey[!is.na(diabetes) & !is.na(neuropathy_outcome), c(1, 9, 7, 10)]



# # 3.4: Clean cvd data --------------------------------------------------------

# Variables are differently named in this dataset.
# In this dataset, neuropathy is also objectively examined by a clinician,
# according to cvd_data[[3]][134, 1:4]

# Diabetes variable:
names(cvd_data[[2]])[grepl("Group",names(cvd_data[[2]]))]
# "Group"

# Neuropathy variables:
# "Neuropathy"
# "Numbness"
# "Painful feet"

# Clean column names and subject ID's:
names(cvd_data[[2]]) <- to_snake_case(names(cvd_data[[2]]))
cvd_data[[2]]$patient_id <- toupper(cvd_data[[2]]$subject_number)

# Filtering to only id, diabetes status and the three neuropathy variables on numbness and pain :
cvd_survey <-
  cvd_data[[2]][, .(
    patient_id,
    diabetes = fifelse(group_2 == "DM", T, F),
    neuropathy,
    numbness,
    painful_feet
  )]


# Recode string data to binary and NAs:

mod_cols = names(cvd_survey)[3:5]
cvd_survey[ , (mod_cols) := lapply(.SD, binary_converter_function), .SDcols = mod_cols]

# Create the simpler neuropathy outcome variable:
# neuropathy is defined as the presence of either neuropathy, or numbness or pain in the feet:

cvd_survey[, neuropathy_outcome := apply(cvd_survey[, 3:5], 1, function(x)
  sum(x, na.rm = T)) >= 1]

# Set individuals with completely missing data to NA:
cvd_survey[, no_neuropathy_data := apply(cvd_survey[, 3:5], 1, function(x)
  sum(is.na(x))) == 3]

cvd_survey[, neuropathy_outcome := fifelse(no_neuropathy_data == T, NA, neuropathy_outcome)]


# Output:
cvd_survey[, dataset := "cvd"]
cvd_clean <- cvd_survey[!is.na(diabetes) & !is.na(neuropathy_outcome), c(1, 2, 6, 8)]



# 4. Combine datasets and summary -------------------------------------------


## 4.1. Append and filter out overlapping individuals:
neuropathy_data <- rbind(cded_visit2_clean, cpd_clean, cves_clean, cvd_clean)

neuropathy_data_visit8 <- rbind(cded_visit8_clean, cpd_clean, cves_clean, cvd_clean)

setkey(neuropathy_data, patient_id)
setkey(neuropathy_data_visit8, patient_id)


## 4.2. Summary -----------------------------------------------------------------

# We now have a combined dataset of:
nrow(neuropathy_data) # 378 observations
nrow(neuropathy_data[, .SD[1], by = patient_id]) # From 346 individuals

# Including
nrow(neuropathy_data[diabetes == T]) # 149 observations from diabetes
nrow(neuropathy_data[diabetes == T, .SD[1], by = patient_id]) # From 138 individuals with diabetes


# But I don't expect ECG data to be available on more than approximately 90 individuals with diabetes.

# I save both datasets, although we may end up only using the cded data from the baseline visit.

# The full data set is saved, including individuals without diabetes and people who may not have ECG data
# We'll see how much is useful when we open the ECG files.


# 5. Summary and save the clean neuropathy datasets ----------------------------------


fwrite(neuropathy_data, file = here("output_data", "neuropathy_visit_2.csv"))
fwrite(neuropathy_data_visit8, file = here("output_data", "neuropathy_visit_8.csv"))



