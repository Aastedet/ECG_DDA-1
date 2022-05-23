---
title: "Data processing workflow in R"
author: "Group 2 Data Science Spring School 2022"
output:
  html_document:
    toc: true
    keep_md: yes
    code_folding: hide
---



# Preface:
This is the repository for ~~Group *Anders*~~ **Group 2** of the Data Science Spring School & Challenge, notorious Kahoot quiz winners!
![img](https://github.com/PandaPowell/ECG_DDA/blob/master/misc/quizwinners.jpg?raw=true)

This document is best viewed on [GitHub Pages](https://pandapowell.github.io/ECG_DDA/index.html).

This project is fully open-source from raw data to output and presentation, so please join and help us improve the model. Sources are contained in the [GitHub repository](https://github.com/PandaPowell/ECG_DDA).

A questionable model unfit for deployment is deployed [here](https://mybinder.org/v2/gh/Aastedet/ecg_neuropathy_app/HEAD?labpath=%2Fvoila%2Frender%2Fecg_neuropathy_app.ipynb).

This repository contains the *R* code used to process data, and also contains four datasets from PhysioNet with data on diabetes and neuropathy status. While ECG data is not contained in the repository, it is available for download on PhysioNet for all datasets, although a substantial proportion of participants are missing ECG or tabular data.

Throughout this document, *R* code to reproduce data processing and population flow is provided in folded chunks below the section of the text where these are mentioned.

The final processing of ECG data and neural network training is performed using Python in a Google Colab Notebook [here](https://colab.research.google.com/drive/1yezNX6pxlHbcWRo08Zk5r23IShMEXZQN?usp=sharing) and [here](https://colab.research.google.com/drive/1_b-j3hDzYTYbbqGdyUnoaGiPZyRMbcJE?usp=sharing). The filtered ECG data output from the `readme.Rmd`  *R* script and used in the notebook can be found on [Google Drive](https://drive.google.com/drive/folders/17AX33KuzP2nZwCQ9sWErY_0bSGI-ON1R?usp=sharing) (or locally in `/ecg_data/` after running the `readme.Rmd` script).

# Aims and summary

This project aimed to train a neural network to be able to predict the risk of an individual having prevalent diabetic neuropathy, using nothing but a ~~standard 12-lead~~ 10 second ECG of two non-standard V1/V2 and V5/V6 leads.

By combining four PhysioNet datasets, data is available on a total of roughly 100 ECGs from 90 individuals with diabetes, who have provided data on neuropathy status. However, ECG data from two of these datasets (a third of the total ECG data) is recorded during vasoregulatory stress testing (e.g. head tilt maneuvers) and was deemed inappropriate for use. Thus, the final dataset consisted of 60 individuals with diabetes from two PhysioNet datasets, with 24 cases of prevalent diabetic neuropathy among these individuals.

Data augmentation was mainly done in the way of splitting the ECG signals into many images of 10-second snippets, in addition to transforming operations (random resizing and cropping, etc.). A ResNet18 computer vision model was transferred and trained on these data, but performance was poor, and very prone to over-fitting.
Particularly challenging was the high level of noise in the ECG data, and data leakage on the individual and source dataset level. The latter was overcome by careful splitting into training and validation datasets, but the former was not addressed. More work to clean the ECG data may enable better performance.

# Data sources

## Overview

-   **Cerebromicrovascular Disease in Elderly with Diabetes**

    -   Abbreviated: **CDED**
    -   Link: <https://physionet.org/content/cded/1.0.0/>
    -   Folder: `/raw_csv_data/GE-79/` 
    -   Contents: 69 participants age 55-75 with or without diabetes

-   **Cerebral perfusion and cognitive decline in type 2 diabetes**

    -   Abbreviated: **CPD**
    -   Link: <https://physionet.org/content/cerebral-perfusion-diabetes/1.0.0/>
    -   Folder: `/raw_csv_data/GE-75/`
    -   Contents: 140 participants age 50-85 years, 70 with type 2 diabetes + 70 without.

-   **Cerebral Vasoregulation in Elderly with Stroke**

    -   Abbreviated: **CVES**
    -   Link: <https://www.physionet.org/content/cves/1.0.0/>
    -   Folder: `/raw_csv_data/GE-72/`
    -   Contents: 120 participants, 60 with stroke, 60 without. Very few with diabetes.

-   **Cerebral Vasoregulation in Diabetes**

    -   Abbreviated: **CVD**
    -   Link: <https://physionet.org/content/cerebral-vasoreg-diabetes/1.0.0/>
    -   Folder: `/raw_csv_data/GE-71/`
    -   Contents: 86 participants age 55-75 years, 37 with type 2 diabetes + 49 without.


```r
# Required packages:
library(dplyr)
library(data.table)
library(here)
library(snakecase)
library(stringr)

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

Using the above method, 24 cases of neuropathy were identified among the 60 individuals in the study population, corresponding to a prevalence around 40% in both datasets (6 of 15 individuals from CDED, 19 of 45 from CPD).


```r
## Define nephropathy in each dataset:


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
binary_converter_function <- function(x) {
  case_when(x == "N/A" ~ NA,
            x == "YES" | x == "yes" | x == "Yes" ~ TRUE,
            x == "NO" | x == "no" | x == "No" ~ FALSE)
}

# Recode string data to binary and NAs:
mod_cols = names(cpd_data_vars)[2:5]
cpd_data_vars[, (mod_cols) := lapply(.SD, binary_converter_function), .SDcols = mod_cols]

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

# Clean CPD dataset (individuals with diabetes, and ECG/neuropathy-data):
cpd_clean <-
  cpd_data_vars[diabetes == T &
                  !is.na(neuropathy_outcome) &
                  patient_id %in% toupper(cpd_data[[4]][ECG == 1]$`Subject ID`), c(1, 6, 8)]



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



# Select columns to be modified
mod_cols = names(cded_survey)[3:5]
cded_survey[, (mod_cols) := lapply(.SD, binary_converter_function), .SDcols = mod_cols]


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

# Clean CDED dataset (visit 2 data from individuals with diabetes and ECG/neuropathy-data, not in CPD):
cded_clean <-
  cded_survey[visit == 2 &
                diabetes == T &
                !is.na(neuropathy_outcome) &
                patient_id %in% toupper(cded_data[[3]][ECG == 1]$`Subject ID`) &
                !patient_id %in% cpd_clean$patient_id, c(1, 6, 8)]



# Merge to one dataset and count neuropathy cases:
neuropathy_final <- rbind(cded_clean, cpd_clean)

nrow(neuropathy_final[dataset == "cded"])
nrow(neuropathy_final[dataset == "cded" & neuropathy_outcome == T])
nrow(neuropathy_final[dataset == "cpd"])
nrow(neuropathy_final[dataset == "cpd" & neuropathy_outcome == T])
```

# Export tabular data and ECG data

## Final cleaning of tabular data:

Append patient id variable to match ECG data file names: 'S' + ID + 'ECG'

The final dataset looks like this before exporting to a csv file:


```r
# Append ID's:
study_dataset <-
  neuropathy_final[, .(
    patient_id = paste0(patient_id, "ECG"),
    dataset = factor(dataset),
    neuropathy_outcome
  )]

# Export dataset
fwrite(study_dataset, file = here("output_data", "study_dataset.csv"))

# Summary and contents:
summary(study_dataset)
```

```
##   patient_id        dataset   neuropathy_outcome
##  Length:60          cded:15   Mode :logical     
##  Class :character   cpd :45   FALSE:35          
##  Mode  :character             TRUE :25
```

```r
study_dataset
```

```
##     patient_id dataset neuropathy_outcome
##  1:   S0105ECG    cded              FALSE
##  2:   S0264ECG    cded               TRUE
##  3:   S0513ECG    cded              FALSE
##  4:   S0536ECG    cded              FALSE
##  5:   S0539ECG    cded              FALSE
##  6:   S0540ECG    cded              FALSE
##  7:   S0543ECG    cded               TRUE
##  8:   S0552ECG    cded               TRUE
##  9:   S0554ECG    cded              FALSE
## 10:   S0555ECG    cded               TRUE
## 11:   S0561ECG    cded              FALSE
## 12:   S0562ECG    cded              FALSE
## 13:   S0582ECG    cded               TRUE
## 14:   S0591ECG    cded              FALSE
## 15:   S0610ECG    cded               TRUE
## 16:   S0250ECG     cpd              FALSE
## 17:   S0256ECG     cpd              FALSE
## 18:   S0273ECG     cpd               TRUE
## 19:   S0282ECG     cpd              FALSE
## 20:   S0287ECG     cpd              FALSE
## 21:   S0288ECG     cpd              FALSE
## 22:   S0292ECG     cpd              FALSE
## 23:   S0296ECG     cpd              FALSE
## 24:   S0300ECG     cpd               TRUE
## 25:   S0301ECG     cpd               TRUE
## 26:   S0304ECG     cpd              FALSE
## 27:   S0308ECG     cpd               TRUE
## 28:   S0310ECG     cpd               TRUE
## 29:   S0312ECG     cpd              FALSE
## 30:   S0314ECG     cpd              FALSE
## 31:   S0315ECG     cpd               TRUE
## 32:   S0316ECG     cpd              FALSE
## 33:   S0317ECG     cpd               TRUE
## 34:   S0318ECG     cpd              FALSE
## 35:   S0326ECG     cpd               TRUE
## 36:   S0327ECG     cpd               TRUE
## 37:   S0339ECG     cpd              FALSE
## 38:   S0342ECG     cpd              FALSE
## 39:   S0349ECG     cpd               TRUE
## 40:   S0365ECG     cpd               TRUE
## 41:   S0366ECG     cpd              FALSE
## 42:   S0372ECG     cpd              FALSE
## 43:   S0381ECG     cpd               TRUE
## 44:   S0382ECG     cpd               TRUE
## 45:   S0390ECG     cpd              FALSE
## 46:   S0392ECG     cpd               TRUE
## 47:   S0398ECG     cpd              FALSE
## 48:   S0403ECG     cpd              FALSE
## 49:   S0405ECG     cpd               TRUE
## 50:   S0406ECG     cpd               TRUE
## 51:   S0409ECG     cpd              FALSE
## 52:   S0416ECG     cpd              FALSE
## 53:   S0420ECG     cpd               TRUE
## 54:   S0423ECG     cpd              FALSE
## 55:   S0424ECG     cpd              FALSE
## 56:   S0426ECG     cpd              FALSE
## 57:   S0430ECG     cpd              FALSE
## 58:   S0432ECG     cpd               TRUE
## 59:   S0433ECG     cpd              FALSE
## 60:   S0434ECG     cpd               TRUE
##     patient_id dataset neuropathy_outcome
```

## Filter, split and export ECG files:

To save space and computation time, we filter the ECGs to only the ones we need, and export them to different folders for labelling purposes. We'll also split the ECGs into training and validation parent folders, so  ECGs from the same experiment or individual cannot be present in both training a validation datasets (we'll be splitting the ECGs into small snippets later, so each individual will contribute multiple ECGs). Otherwise we risk [data leakage](https://en.wikipedia.org/wiki/Leakage_(machine_learning)) between the training and validation datasets, and the model might learn to identify *individuals* or *experiment*, rather than signals of *neuropathy*, which would erode model performance on external data. A somewhat famous example of this mistake being [Andrew Ng's random split of 112,120 x-ray images from 30,805 individuals](https://twitter.com/nizkroberts/status/931121395748270080) which was subsequently corrected.

Fortunately, the CPD and CDED datasets are similarly balanced in terms of neuropathy prevalence, and their relative sizes are suitable for use as a training/validation split (the CDED participants make up 25% of the study population). Due to the limited data available, we do not set aside a test dataset, but expect performance on external datasets to be relatively stable due to the different sources of training and validation set.


```r
# Specify local source folder of CDED and CPD ECG data:
cded_ecg_folder <-
  "C:/physionet/cded/cerebromicrovascular-disease-in-elderly-with-diabetes-1.0.0/Data/ECG/"

cpd_ecg_folder <- "C:/physionet/cpd/data/ecg"


# List ECG files of all patients in study population
cded_files <- list.files(cded_ecg_folder,
                         full.names = T)

cpd_files <- list.files(cpd_ecg_folder,
                        full.names = T)


# Filter files of each dataset to only subjects in study population and split into groups based on neuropathy status:

# CDED:
cded_healthy <-
  cded_files[str_sub(cded_files, -12, -5) %in% study_dataset[dataset == "cded" &
                                                               neuropathy_outcome == FALSE]$patient_id]

cded_neuropathy <-
  cded_files[str_sub(cded_files, -12, -5) %in% study_dataset[dataset == "cded" &
                                                               neuropathy_outcome == TRUE]$patient_id]

# CPD:
cpd_healthy <-
  cpd_files[str_sub(cpd_files, -12, -5) %in% study_dataset[dataset == "cpd" &
                                                             neuropathy_outcome == FALSE]$patient_id]

cpd_neuropathy <-
  cpd_files[str_sub(cpd_files, -12, -5) %in% study_dataset[dataset == "cpd" &
                                                             neuropathy_outcome == TRUE]$patient_id]
```

In this fashion, we end up with a training set containing 45 individuals, and a validation set containing 15 individuals.

Training set:


```r
unique(str_sub(
  c(
    cpd_healthy,
    cpd_neuropathy
  ),
  -12,
  -5
))
```

```
##  [1] "S0250ECG" "S0256ECG" "S0282ECG" "S0287ECG" "S0288ECG" "S0292ECG"
##  [7] "S0296ECG" "S0304ECG" "S0312ECG" "S0314ECG" "S0316ECG" "S0318ECG"
## [13] "S0339ECG" "S0342ECG" "S0366ECG" "S0372ECG" "S0390ECG" "S0398ECG"
## [19] "S0403ECG" "S0409ECG" "S0416ECG" "S0423ECG" "S0424ECG" "S0426ECG"
## [25] "S0430ECG" "S0433ECG" "S0273ECG" "S0300ECG" "S0301ECG" "S0308ECG"
## [31] "S0310ECG" "S0315ECG" "S0317ECG" "S0326ECG" "S0327ECG" "S0349ECG"
## [37] "S0365ECG" "S0381ECG" "S0382ECG" "S0392ECG" "S0405ECG" "S0406ECG"
## [43] "S0420ECG" "S0432ECG" "S0434ECG"
```

Validation set:


```r
unique(str_sub(
  c(
    cded_healthy,
    cded_neuropathy
  ),
  -12,
  -5
))
```

```
##  [1] "S0105ECG" "S0513ECG" "S0536ECG" "S0539ECG" "S0540ECG" "S0554ECG"
##  [7] "S0561ECG" "S0562ECG" "S0591ECG" "S0264ECG" "S0543ECG" "S0552ECG"
## [13] "S0555ECG" "S0582ECG" "S0610ECG"
```

```r
cded_healthy
```

```
##  [1] "C:/physionet/cded/cerebromicrovascular-disease-in-elderly-with-diabetes-1.0.0/Data/ECG/S0105ECG.dat"
##  [2] "C:/physionet/cded/cerebromicrovascular-disease-in-elderly-with-diabetes-1.0.0/Data/ECG/S0105ECG.hea"
##  [3] "C:/physionet/cded/cerebromicrovascular-disease-in-elderly-with-diabetes-1.0.0/Data/ECG/S0513ECG.dat"
##  [4] "C:/physionet/cded/cerebromicrovascular-disease-in-elderly-with-diabetes-1.0.0/Data/ECG/S0513ECG.hea"
##  [5] "C:/physionet/cded/cerebromicrovascular-disease-in-elderly-with-diabetes-1.0.0/Data/ECG/S0536ECG.dat"
##  [6] "C:/physionet/cded/cerebromicrovascular-disease-in-elderly-with-diabetes-1.0.0/Data/ECG/S0536ECG.hea"
##  [7] "C:/physionet/cded/cerebromicrovascular-disease-in-elderly-with-diabetes-1.0.0/Data/ECG/S0539ECG.dat"
##  [8] "C:/physionet/cded/cerebromicrovascular-disease-in-elderly-with-diabetes-1.0.0/Data/ECG/S0539ECG.hea"
##  [9] "C:/physionet/cded/cerebromicrovascular-disease-in-elderly-with-diabetes-1.0.0/Data/ECG/S0540ECG.dat"
## [10] "C:/physionet/cded/cerebromicrovascular-disease-in-elderly-with-diabetes-1.0.0/Data/ECG/S0540ECG.hea"
## [11] "C:/physionet/cded/cerebromicrovascular-disease-in-elderly-with-diabetes-1.0.0/Data/ECG/S0554ECG.dat"
## [12] "C:/physionet/cded/cerebromicrovascular-disease-in-elderly-with-diabetes-1.0.0/Data/ECG/S0554ECG.hea"
## [13] "C:/physionet/cded/cerebromicrovascular-disease-in-elderly-with-diabetes-1.0.0/Data/ECG/S0561ECG.dat"
## [14] "C:/physionet/cded/cerebromicrovascular-disease-in-elderly-with-diabetes-1.0.0/Data/ECG/S0561ECG.hea"
## [15] "C:/physionet/cded/cerebromicrovascular-disease-in-elderly-with-diabetes-1.0.0/Data/ECG/S0562ECG.dat"
## [16] "C:/physionet/cded/cerebromicrovascular-disease-in-elderly-with-diabetes-1.0.0/Data/ECG/S0562ECG.hea"
## [17] "C:/physionet/cded/cerebromicrovascular-disease-in-elderly-with-diabetes-1.0.0/Data/ECG/S0591ECG.dat"
## [18] "C:/physionet/cded/cerebromicrovascular-disease-in-elderly-with-diabetes-1.0.0/Data/ECG/S0591ECG.hea"
```


Since the proportion of neuropathy is balanced between the two datasets, we also train a model on a random 20/80 split for comparison (due to the balanced proportions, an increased performance after training on both datasets should not be due to data leakage):


```r
# Alternative random split:
# Sample 1 in 5 of all participants to validation dataset:
all_participant_files <- c(cded_healthy, cded_neuropathy, cpd_healthy, cpd_neuropathy)


all_healthy <- all_participant_files[str_sub(all_participant_files, -12, -5) %in% study_dataset[neuropathy_outcome == FALSE]$patient_id]

all_neuropathy <- all_participant_files[str_sub(all_participant_files, -12, -5) %in% study_dataset[neuropathy_outcome == TRUE]$patient_id]
# Set seed for reproducibility:

set.seed(2)

valid_healthy <- all_participant_files[str_sub(all_participant_files, -12, -5) %in% sample(study_dataset[neuropathy_outcome == FALSE]$patient_id, 0.20 * nrow(study_dataset[neuropathy_outcome == FALSE]))]

valid_neuropathy <- all_participant_files[str_sub(all_participant_files, -12, -5) %in% sample(study_dataset[neuropathy_outcome == TRUE]$patient_id, 0.20 * nrow(study_dataset[neuropathy_outcome == TRUE]))]

# And remove the validation individuals from the training set:
train_healthy <- all_healthy[!all_healthy %in% valid_healthy]


train_neuropathy <- all_neuropathy[!all_neuropathy %in% valid_neuropathy]
```


For labeling purposes, training  set ECGs from individuals with neuropathy go to the `/ecg_wfdb/train/neuropathy/` folder, and those without neuropathy go to the `/ecg_wfdb/train/healthy/` folder. Conversely, validation set ECGs go to their respective `/ecg_wfdb/valid/neuropathy/` and `/ecg_wfdb/valid/healthy/` folders. Like so:

```
/ecg_wfdb
├── /train
│   ├── /healthy/
│   └── /neuropathy/
└── /valid
    ├── /healthy/
    └── /neuropathy/

```


```r
# Copy these files to either /healthy/ or /neuropathy/ folders based on neuropathy status:

# Split by source dataset:

# Training set:
# Healthy:
file.copy(from = cpd_healthy, to = here("ecg_wfdb", "train", "healthy"))

# Neuropathy:
file.copy(from = cpd_neuropathy, to = here("ecg_wfdb", "train", "neuropathy"))


# Validation set:
# Healthy:
file.copy(from = cded_healthy, to = here("ecg_wfdb", "valid", "healthy"))


# Neuropathy:
file.copy(from = cded_neuropathy, to = here("ecg_wfdb", "valid", "neuropathy"))




# Random split:

# Training set:
# Healthy:
file.copy(from = train_healthy, to = here("ecg_wfdb_randomsplit", "train", "healthy"))

# Neuropathy:
file.copy(from = train_neuropathy, to = here("ecg_wfdb_randomsplit", "train", "neuropathy"))


# Validation set:
# Healthy:
file.copy(from = valid_healthy, to = here("ecg_wfdb_randomsplit", "valid", "healthy"))


# Neuropathy:
file.copy(from = valid_neuropathy, to = here("ecg_wfdb_randomsplit", "valid", "neuropathy"))
```

Note that the ECG data files aren't tracked in Git, so you'll have to download the datasets from PhysioNet to reproduce this.

# Off to Python and Google Colab!

Now, we have no further use of the tabular data file, since all the information needed to run the model is contained in the filename and path of the ECG data itself at this point (neuropathy label in the folder name, ECG ID in the file name).

The rest of the data processing is carried out in [Python on Google Colab](https://colab.research.google.com/) ([preprocessing here](https://drive.google.com/file/d/1L9HoCpwvcAg84XY1d-mqiYqTXxO004uY/view?usp=sharing), [transfer learning here](https://colab.research.google.com/drive/1_b-j3hDzYTYbbqGdyUnoaGiPZyRMbcJE?usp=sharing) , and involves reading the ECG data's waveform signals, extracting the two ECG leads and splitting them into hundreds of 10 second snippets saved as separate image files, which are then loaded into fastai DataLoader objects to train a ResNet model.

**See you on the other side!**
