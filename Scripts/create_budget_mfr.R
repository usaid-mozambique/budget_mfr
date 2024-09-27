library(tidyverse)
library(blingr)

# Filters -----------------------------------------------------------------------
OBLIGATION_TYPE_FILTER <- c("OBLG_UNI", "OBLG_SUBOB")
DISTRIBUTION_FILTER <- c("656-M", "656-GH-M", "656-W", "656-GH-W")
REMOVE_AWARDS <- c("MEL")

# PATHS ----------------------------------------------------------
ACTIVE_AWARDS_FOLDER_PATH <- "Data/active_awards/"
OBLG_ACC_LINES_PATH <- "Data/obligation_acc_lines/"
TRANSACTION_PATH <- "Data/transaction/"
OUTPUT_PATH <- "Dataout/"

#READ IN ALL DATA---------------------------------------------------------------------

#1. Active Awards (maintained by team as a google sheet but downloaded each month)----
active_awards_input_file <- dir(ACTIVE_AWARDS_FOLDER_PATH,
                                full.name = TRUE,
                                pattern = "*.xlsx")

active_awards_df <- map(active_awards_input_file, ~blingr::clean_awards(.x, "Active Awards")) |> 
    bind_rows() |> 
    filter(!str_detect(activity_name, paste(REMOVE_AWARDS, collapse = "|"))) |> 
    mutate(period = lubridate::ym(period)) #convert to date


write_csv(active_awards_df, paste0(OUTPUT_PATH, "active_awards.csv"))

#create list of active award numbers to be used to pull out data from Phoenix
active_awards_number <-  active_awards_df |> 
    pull(award_number) |> 
    unique() 



#2. Read subobligation plan - manual file maintained by team as a google sheet (downloaded monthly)----
subobligation_input_file <- dir("Data/subobligation_summary/",
                                full.name = TRUE,
                                pattern = "*.xlsx")

subobligation_summary_df <- map(subobligation_input_file, blingr::clean_subobligation_summary) |> 
    bind_rows() |> 
    filter(award_number %in% active_awards_number) |>  #only keep active awards
    mutate(period = lubridate::ym(period)) #convert to date

write_csv(subobligation_summary_df, paste0(OUTPUT_PATH, "subobligation_summary.csv"))

#3. Read obligation accounting lines (similar to pipeline) from phoenix----
obl_acc_lines_input_file <- dir(OBLG_ACC_LINES_PATH,
                                full.name = TRUE,
                                pattern = "*.xlsx")


phoenix_obl_acc_lines_df <- map(obl_acc_lines_input_file, ~ blingr::clean_phoenix_oblg_acc_lines(.x, 
                                                                                                 active_awards_number, 
                                                                                                 OBLIGATION_TYPE_FILTER, 
                                                                                                 DISTRIBUTION_FILTER)) |> 
    bind_rows()


write_csv(phoenix_obl_acc_lines_df, paste0(OUTPUT_PATH, "phoenix_obl_acc_lines.csv"))

#4. Read transaction data from phoenix and show transaction date monthly----
transaction_input_file <- dir(TRANSACTION_PATH,
                              full.name = TRUE,
                              pattern = "*.xlsx")

phoenix_transaction_df <- map(transaction_input_file, ~ blingr::clean_phoenix_transaction(.x, 
                                                                                          active_awards_number,
                                                                                          DISTRIBUTION_FILTER, 
                                                                                          "month")
) |> 
    bind_rows() |> 
    distinct() |>   #remove any duplicate rows
    blingr::create_phoenix_transaction_cumulative()

write_csv(phoenix_transaction_df, paste0(OUTPUT_PATH, "phoenix_transaction.csv"))

#-------------do this in Tableau not here
# CREATE DATASETS -----------------------------------------------------------------------------------

# 1. Obligation Accounting Lines

active_awards_one_row <- active_awards_df |> 
    left_join(phoenix_obl_acc_lines_df, by = c("award_number", "period")) |> 
    left_join(subobligation_summary_df, by = c("award_number", "period", "program_area"))|> 
    left_join(phoenix_transaction_df, by = c("award_number",  "period" = "transaction_date" , "program_area")) 

colnames(phoenix_transaction_df)



# 2. Transaction NB:  no accruals (main difference from QFR) ----
active_awards_one_row_transaction <- active_awards_df |> 
    select(award_number, activity_name) |> 
    distinct() |> #needed as there are multiple lines due to period
    left_join(phoenix_transaction_df, by = "award_number") |> 
    select(award_number, activity_name, transaction_disbursement,
           transaction_obligation, transaction_amt, avg_monthly_exp_rate, 
           period, program_area, transaction_date, program_area_name, cumulative_transaction_disbursement_fy) 


# OUTPUT DATASETS---------------------------------------------------------------

write_csv(active_awards_one_row_transaction, paste0(OUTPUT_PATH, "active_awards_one_row_transaction.csv"))




