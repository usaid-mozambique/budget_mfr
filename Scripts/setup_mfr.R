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
folder_setup(folder_list = list("Data/active_awards",   #active awards google sheet. download monthly snapshot
                                "Data/subobligation_summary", #monthly subobligation summary.  download monthly snapshot
                                "Data/transaction", #phoenix transaction data
                                "Data/obligation_acc_lines" #phoenix obligation accounting lines data
                                
)
)
