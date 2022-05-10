---
title: "Overview and flow of tabular data"
author: "Anders Group Data Science Spring School 2022"
output:
  html_document:
    toc: true
    keep_md: yes
    code_folding: hide
---



# Aims and summary

This project aims to train a neural network to be able to predict the risk of an individual having prevalent diabetic neuropathy, using nothing but a standard 12-lead ECG.

By combining four PhysioNet datasets, data is available on roughly 100 ECG from 90 individuals with diabetes, who have provided data on neuropathy status. ECG data from two of these datasets (a third of the total ECG data) is recorded during vasoregulatory stress testing (e.g. head tilt maneuvres) and may be inappropriate for use.

## Data sources

### Overview

GitHub link: https://github.com/PandaPowell/ECG_DDA

This repository contains the following four datasets from PhysioNet with data on diabetes and neuropathy status. ECG data is available for all datasets, but not on all participants, and some individuals having missing tabular data.
Throughout this document, *R* code to reproduce calculations and population flow is provided in folded chunks below the section of the text where these are mentioned.


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


*Code to load data:*

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
- CDED: 82
- CPD: 88
- CVES: 172
- CVD: 86
- Combined: 391

*Code:*

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

- CDED: 47
- CPD: 51
- CVES: 91
- CVD: 57
- Combined: 220


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

- CDED: 22
- CPD: 45
- CVES: 2
- CVD: 29
- Combined: 90

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

Overlap in participants (with ECG data and diabetes) between the datasets is limited to 8 participants in CDED, who are also in CPD (7) and CVD (1).

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

