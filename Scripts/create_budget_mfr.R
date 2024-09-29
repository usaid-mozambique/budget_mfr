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


#READ AND CLEAN ALL DATA ---------------------------------------------

#READ IN ALL DATA---------------------------------------------------------------------

#1. Active Awards (maintained by team as a google sheet but downloaded each month)----
active_awards_input_file <- dir(ACTIVE_AWARDS_FOLDER_PATH,
                                full.name = TRUE,
                                pattern = "*.xlsx")

active_awards_df <- map(active_awards_input_file, ~blingr::clean_awards(.x, "Active Awards")) |> 
    bind_rows() |> 
    filter(!str_detect(activity_name, paste(REMOVE_AWARDS, collapse = "|"))) |> 
    mutate(period = lubridate::ym(period)) |>  #convert to date 
    mutate(fiscal_year_active_awards = lubridate::year(period))  # moved back


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
                                                                                          DISTRIBUTION_FILTER)
) |> 
    bind_rows() |> 
    select(-program_area_name) |> 
    rename("period_fy" = period)


phoenix_transaction_cumulative_df <- phoenix_transaction_df |> 
    blingr::create_phoenix_transaction_cumulative()


#

write_csv(phoenix_transaction_df, paste0(OUTPUT_PATH, "phoenix_transaction.csv"))


# CREATE DATASETS-----------------------------
#1. Pipeline ----------------------
pipeline_dataset <- active_awards_df |> 
    left_join(phoenix_obl_acc_lines_df, by = c("award_number", "period")) |> 
    left_join(subobligation_summary_df, by = c("award_number", "period", "program_area")) |> 
    left_join(phoenix_transaction_df, by = c("award_number", "period" = "transaction_date_month", "program_area")) |> 
    left_join(phoenix_transaction_cumulative_df, by = c("award_number", "fiscal_year_active_awards" = "fiscal_year", "program_area"))

write_csv(pipeline_dataset,"Dataout/pipeline.csv")

#2. Transaction -------------------
transaction_dataset <- active_awards_df |> 
    select(award_number, activity_name) |> 
    left_join(phoenix_transaction_df, by = "award_number") |> 
    left_join(phoenix_transaction_cumulative_df, by = c("award_number", "program_area","fiscal_year"))


write_csv(transaction_dataset, "Dataout/transaction.csv")


