required_packages <- c("tidyverse", "janitor", "glamr", "blingr")

# Install blingr from GitHub if not installed
if (!"blingr" %in% installed.packages()[, "Package"]) {
    if (!requireNamespace("remotes", quietly = TRUE)) {
        install.packages("remotes")
    }
    remotes::install_github("usaid-mozambique/blingr")
}

# Install other missing packages from the specified repos
missing_packages <- setdiff(required_packages, installed.packages()[, "Package"])

if (length(missing_packages) > 0) {
    install.packages(missing_packages, repos = c("https://usaid-oha-si.r-universe.dev",
                                                 "https://cloud.r-project.org"))
}

library(glamr)
library(tidyverse)
library(janitor)
library(blingr)


# OTHER SETUP  - only run one-time --------------------------------------

folder_setup() 
folder_setup(folder_list = list("Data/bi_acc_lines/raw",   #bilateral accounting lines raw data here - one file at a time
                                "Data/open_commitment/raw", #open commitment raw data - one file at a time
                                "Data/bi_acc_lines/processed/non_pepfar", #processed data for non-pepfar
                                "Data/open_commitment/processed/non_pepfar", #processed data for non-pepfar
                                "Data/bi_acc_lines/processed/pepfar", #processed data for pepfar
                                "Data/open_commitment/processed/pepfar"
)
)


