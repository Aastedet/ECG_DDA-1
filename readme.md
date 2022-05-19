---
title: "Overview and flow of tabular data"
author: "Anders Group Data Science Spring School 2022"
output:
  html_document:
    toc: true
    keep_md: yes
    code_folding: hide
---



# Preface:

This document is best viewed on the [properly formatted html page](<https://htmlpreview.github.io/?https://github.com/PandaPowell/ECG_DDA/blob/master/readme.html>).

Sources are contained in the [GitHub repository](<https://github.com/PandaPowell/ECG_DDA>).

This repository contains the following four datasets from PhysioNet with data on diabetes and neuropathy status. ECG data is available for all datasets, but not on all participants, and some individuals having missing tabular data.

Throughout this document, *R* code to reproduce data processing and population flow is provided in folded chunks below the section of the text where these are mentioned.

# Aims and summary

This project aimed to train a neural network to be able to predict the risk of an individual having prevalent diabetic neuropathy, using nothing but a ~~standard 12-lead~~ 10 second ECG of two non-standard V1/V2 and V5/V6 leads.

By combining four PhysioNet datasets, data is available on a total of roughly 100 ECGs from 90 individuals with diabetes, who have provided data on neuropathy status. However, ECG data from two of these datasets (a third of the total ECG data) is recorded during vasoregulatory stress testing (e.g. head tilt maneuvers) and was deemed inappropriate for use.
Thus, the final dataset consisted of 60 individuals with diabetes from two PhysioNet datasets, with 24 cases of prevalent diabetic neuropathy among these individuals.

# Data sources

## Overview

-   **Cerebromicrovascular Disease in Elderly with Diabetes**

    -   Abbreviated: **CDED**
    -   Link: <https://physionet.org/content/cded/1.0.0/>
    -   Folder: "/GE-79"
    -   Contents: 69 participants age 55-75 with or without diabetes

-   **Cerebral perfusion and cognitive decline in type 2 diabetes**

    -   Abbreviated: **CPD**
    -   Link: <https://physionet.org/content/cerebral-perfusion-diabetes/1.0.0/>
    -   Folder: "/GE-75"
    -   Contents: 140 participants age 50-85 years, 70 with type 2 diabetes + 70 without.

-   **Cerebral Vasoregulation in Elderly with Stroke**

    -   Abbreviated: **CVES**
    -   Link: <https://www.physionet.org/content/cves/1.0.0/>
    -   Folder: "/GE-72"
    -   Contents: 120 participants, 60 with stroke, 60 without. Very few with diabetes.

-   **Cerebral Vasoregulation in Diabetes**

    -   Abbreviated: **CVD**
    -   Link: <https://physionet.org/content/cerebral-vasoreg-diabetes/1.0.0/>
    -   Folder: "/GE-71"
    -   Contents: 86 participants age 55-75 years, 37 with type 2 diabetes + 49 without.




```r
# Required packages:
library(dplyr)
library(data.table)
library(here)
library(snakecase)

# Load tabular data:

# From "Cerebromicrovascular Disease in Elderly with Diabetes" ("GE-79"):
# https://physionet.org/content/cded/1.0.0/
cded_data <-
  lapply(list.files(here("raw_csv_data", "GE-79"), full.names = T), fread, stringsAsFactors = F)

# From "Cerebral perfusion and cognitive decline in type 2 diabetes" ("GE-75"):
# https://physionet.org/content/cerebral-perfusion-diabetes/1.0.0/
cpd_data <-
  lapply(list.files(here("raw_csv_data", "GE-75"), full.names = T), fread, stringsAsFactors = F)


# From "Cerebral Vasoregulation in Diabetes" ("GE-71"):
# https://physionet.org/content/cerebral-vasoreg-diabetes/1.0.0/
cvd_data <-
  lapply(list.files(here("raw_csv_data", "GE-71"), full.names = T), fread, stringsAsFactors = F)

# From: "Cerebral Vasoregulation in Elderly with Stroke" ("GE-72"):
# https://www.physionet.org/content/cves/1.0.0/
cves_data <-
  fread(list.files(here("raw_csv_data", "GE-72"), full.names = T), stringsAsFactors = F)
```

## Actual size of usable data

The above contents are what the documentation describes. That does not match the size of the tabular data actually in the datasets, and some individuals may be present in more than one dataset.

### Unique subjects in each dataset and in a combined dataset:

-   CDED: 82
-   CPD: 88
-   CVES: 172
-   CVD: 86
-   Combined: 391




```r
# Unique subjects in each dataset:

# CDED:
length(unique(cded_data[[3]]$`Subject ID`))

# CPD:
length(unique(cpd_data[[4]]$`Subject ID`))

# CVES:
length(unique(cves_data$subject_number))

# CVD:
length(unique(cvd_data[[4]]$`Subject ID`))

# Unique subjects in total:
length(unique(toupper(
  c(
    cded_data[[3]]$`Subject ID`,
    cpd_data[[4]]$`Subject ID`,
    cves_data$subject_number,
    cvd_data[[4]]$`Subject ID`
  )
)))
```

### Unique subjects with ECG data available

All four datasets include data on whether ECG data is missing or not. In the CDED and CPD datasets, this is described with an explicit variable. In the CVES and CVD datasets, we're making a qualified guess based on whether that person completed the visit where ECGs were performed:

-   CDED: 47
-   CPD: 51
-   CVES: 91
-   CVD: 57
-   Combined: 220


```r
# Unique subjects in each dataset with ECG data:

# CDED:
length(unique(cded_data[[3]][ECG == 1]$`Subject ID`))

# CPD:
length(unique(cpd_data[[4]][ECG == 1]$`Subject ID`))

# CVES:
length(unique(cves_data[completed_visit_status == "COMPLETED"]$subject_number))

# CVD:
length(unique(cvd_data[[4]][`Head Up Tilt D2` == 1]$`Subject ID`))

# Unique subjects in total:
length(unique(toupper(
  c(
    cded_data[[3]][ECG == 1]$`Subject ID`,
    cpd_data[[4]][ECG == 1]$`Subject ID`,
    cves_data[completed_visit_status == "COMPLETED"]$subject_number,
    cvd_data[[4]][`Head Up Tilt D2` == 1]$`Subject ID`
  )
)))
```

### Unique subjects in each dataset with ECG data, who have diabetes

All four datasets provide data on diabetes status. Note that these individuals may provide more than one ECG, e.g. if ECGs are performed at baseline and at follow-up:

-   CDED: 22
-   CPD: 45
-   CVES: 2
-   CVD: 29
-   Combined: 90


```r
# Unique subjects in each dataset with ECG data, who have diabetes:

# CDED:
length(unique(cded_data[[3]][ECG == 1 & toupper(`Subject ID`) %in% toupper(cded_data[[6]][`DM PATIENT MEDICAL HISTORY` == "YES"]$`patient ID`)]$`Subject ID`))

# CPD:
length(unique(cpd_data[[4]][ECG == 1 & Group == "DM"]$`Subject ID`))

# CVES:
length(unique(cves_data[completed_visit_status == "COMPLETED" & `DM PATIENT MEDICAL HISTORY` %in% c("yes", "YES")]$subject_number))

# CVD:
length(unique(cvd_data[[4]][`Head Up Tilt D2` == 1 & Group %in% c("DM", "DMOH")]$`Subject ID`))

# Unique subjects in total:
length(unique(toupper(
  c(
    cded_data[[3]][ECG == 1 &
                     toupper(`Subject ID`) %in% toupper(cded_data[[6]][`DM PATIENT MEDICAL HISTORY` == "YES"]$`patient ID`)]$`Subject ID`,
    cpd_data[[4]][ECG == 1 & Group == "DM"]$`Subject ID`,
    cves_data[completed_visit_status == "COMPLETED" &
                `DM PATIENT MEDICAL HISTORY` %in% c("yes", "YES")]$subject_number,
    cvd_data[[4]][`Head Up Tilt D2` == 1 &
                    Group %in% c("DM", "DMOH")]$`Subject ID`
  )
)))
```

### Participant overlap between datasets

Overlap in participants (with ECG data and diabetes) between the datasets is limited to 8 participants in CDED, who are also present in CPD (7) and CVD (1).


```r
### Overlap between cded and cpd/cves/cvd:
# This could have been done more elegant, but bear with me)

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
                 toupper(`Subject ID`) %in% toupper(cvd_data[[4]][`Head Up Tilt D2` == 1 &
                                                                    Group %in% c("DM", "DMOH")]$`Subject ID`)]


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

### No overlap between cves and cvd: 0
nrow(cves_data[completed_visit_status == "COMPLETED" &
                 `DM PATIENT MEDICAL HISTORY` %in% c("yes", "YES") &
                 toupper(subject_number) %in% toupper(cvd_data[[4]][`Head Up Tilt D2` == 1 &
                                                                      Group %in% c("DM", "DMOH")]$`Subject ID`)])
```

# Study dataset: Individuals in CDED and CPD with diabetes, and data on ECG and neuropathy

For the models, we combined CDED (data from baseline visit) and CPD datasets, excluding records in the CPD data from the 7 individuals already present in the CDED dataset and leaving a final study population of 60 individuals.

## Prevalence of diabetic neuropathy

The protocol states that neuropathy in the CDED dataset was diagnosed at some point using the validated symptom scale [neuropathy total symptom score-6](https://doi.org/10.1016/j.clinthera.2005.08.002), but the available variables do not correspond to this.

Both CDED and CPD contain questionnaire data on numbness and painful sensations of the feet. The CPD dataset also contains an item on autonomic neuropathy symptoms, although it is unclear what specific symptoms this item covers.

We defined diabetic neuropathy as a binary variable on the individual level as the presence of at least one of these symptoms. Individuals with missing data on all neuropathy items were excluded, while cases with missing data on only some items were interpreted as having no symptoms of these types.

### Final dataset

Using the above method, 24 cases of neuropathy were identified among the 60 individuals in the study population (7 of 22 individuals from CDED, 17 of 38 from CPD).


```r
## Define nephropathy in each dataset:

### CDED:
#### Make column names prettier for future use and clean case inconsistency in ID variable:
names(cded_data[[6]]) <- to_snake_case(names(cded_data[[6]]))
cded_data[[6]]$patient_id <-  toupper(cded_data[[6]]$patient_id)

# Filter to variables needed:
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


# Create a simple neuropathy variable:
# neuropathy is defined as the presence of either numbness or pain in the feet:
# The few cases of missing data in a symptom variable is treated as no symptom of this kind.
cded_survey[, neuropathy_outcome := apply(cded_survey[, 4:5], 1, function(x)
  sum(x, na.rm = T)) >= 1]

# Set individuals with completely missing data to NA:
cded_survey[, no_neuropathy_data := apply(cded_survey[, 4:5], 1, function(x)
  sum(is.na(x))) == 2]

cded_survey[, neuropathy_outcome := fifelse(no_neuropathy_data == T, NA, neuropathy_outcome)]

# Rename diabetes variable for convenience:
names(cded_survey)[3] <- "diabetes"

# Add variable to keep track of which dataset overlapping individuals came from:
cded_survey[, dataset := "cded"]

# Clean CDED dataset (visit 2 data from individuals with diabetes and ECG/neuropathy-data):
cded_clean <- cded_survey[visit == 2 & diabetes == T & !is.na(neuropathy_outcome) & patient_id %in% toupper(cded_data[[3]][ECG == 1]$`Subject ID`), c(1, 6, 8)]



### CPD:
# Clean column names and subject ID's:
names(cpd_data[[2]]) <- to_snake_case(names(cpd_data[[2]]))
cpd_data[[2]]$patient_id <- toupper(cpd_data[[2]]$patient_id)

# Filtering to only id, diabetes status and the three neuropathy variables on numbness and pain :
cpd_data_vars <-
  cpd_data[[2]][, .(
    patient_id,
    dm_patient_medical_history,
    neuropathy_autonomic_symptoms,
    numbness_autonomic_symptoms,
    painful_feet_autonomic_symptoms
  )]



# Recode string data to binary and NAs:
mod_cols = names(cpd_data_vars)[2:5]
cpd_data_vars[ , (mod_cols) := lapply(.SD, binary_converter_function), .SDcols = mod_cols]

# Create the simpler neuropathy outcome variable:
# neuropathy is defined as the presence of either neuropathy, or numbness or pain in the feet:
cpd_data_vars[, neuropathy_outcome := apply(cpd_data_vars[, 3:5], 1, function(x)
  sum(x, na.rm = T)) >= 1]

# Set individuals with completely missing data to NA:
cpd_data_vars[, no_neuropathy_data := apply(cpd_data_vars[, 3:5], 1, function(x)
  sum(is.na(x))) == 3]

cpd_data_vars[, neuropathy_outcome := fifelse(no_neuropathy_data == T, NA, neuropathy_outcome)]


# rename diabetes variable and dataset variable for convenience:
names(cpd_data_vars)[2] <- "diabetes"
cpd_data_vars[, dataset := "cpd"]

# Clean CPD dataset (individuals not in CDED, with diabetes, and ECG/neuropathy-data):
cpd_clean <- cpd_data_vars[!patient_id %in% cded_clean$patient_id & diabetes == T & !is.na(neuropathy_outcome) & patient_id %in% toupper(cpd_data[[4]][ECG == 1]$`Subject ID`), c(1, 6, 8)]

# Merge to one dataset and count neuropathy cases:
neuropathy_final <- rbind(cded_clean, cpd_clean)

nrow(neuropathy_final[dataset =="cded" & neuropathy_outcome == T])
nrow(neuropathy_final[dataset =="cpd" & neuropathy_outcome == T])
```