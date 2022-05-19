# Filter ECG data to study population (and split into folders by neuropathy label)

library(fs)
library(here)
library(data.table)

# Load study population and split by neuropathy label

study_pop_healthy <-
  rbindlist(lapply(
    list.files(
      here("output_data"),
      full.names = T,
      pattern = "healthy"
    ),
    fread,
    stringsAsFactors = F
  ))

study_pop_neuropathy <-
  rbindlist(lapply(
    list.files(
      here("output_data"),
      full.names = T,
      pattern = "neuropathy"
    ),
    fread,
    stringsAsFactors = F
  ))

# Add local source folder of CDED and CPD ECG data:

cded_ecg_folder <- "C:/physionet/cded/cerebromicrovascular-disease-in-elderly-with-diabetes-1.0.0/Data/ECG/"
cpd_ecg_folder <- "C:/physionet/cpd/data/ecg"

# Copy ECGs of the study population to subfolders in the /ecg_data folder (folder not tracked due to large data size)
