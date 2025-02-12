library(knitr)
library(lubridate)
library(readr)
library(zip)
library(dplyr)
library(stringr)

clean_zip_data <- function(trap_path, new_path) {
  # Temporary directories for extraction and writing
  folder_path <- "data/knights_landing.zip"
  temp_dir <- tempdir()
  temp_dir <- normalizePath(temp_dir, winslash = "/")
  original_wd <- getwd()

  # Unzip new_path
  unzip(folder_path, exdir = temp_dir)
  print(temp_dir)
  trap_file <- file.path(temp_dir, basename(trap_path))
  trap_data <- readr::read_csv(trap_file) |>
    arrange(subSiteName, visitTime) |>
    mutate(trap_start_date = ymd_hms(case_when(visitType %in% c("Continue trapping", "Unplanned restart", "End trapping") ~ lag(visitTime2),
                                               T ~ visitTime)),
           trap_end_date = ymd_hms(case_when(visitType %in% c("Continue trapping", "Unplanned restart", "End trapping") ~ visitTime,
                                             T ~ visitTime2)))

  new_file <- file.path(temp_dir, basename(new_path))
  cleaned_data <- if (grepl("knights_landing_catch.csv", new_path)) {
    readr::read_csv(new_file) |>
      mutate(run = ifelse(run %in% c("Not applicable (n/a)", "Not recorded"), NA, run)) |>
      arrange(subSiteName, visitTime) |>
      left_join(trap_data |>
                  select(trapVisitID, trap_start_date, trap_end_date))
  }else if(grepl("knights_landing_recapture.csv", new_path)) {
    readr::read_csv(new_file) |>
      left_join(trap_data |>
                  select(trapVisitID, visitTime, visitTime2, trap_start_date, trap_end_date) |>
                  distinct()) |>
      mutate(run = ifelse(run %in% c("Not applicable (n/a)", "Not recorded"), NA, run)) |>
      select(ProjectDescriptionID, catchRawID, trapVisitID, commonName, releaseID, run, fishOrigin, lifeStage, forkLength, n,
             visitTime, visitTime2, visitType, siteName, subSiteName, markType, markColor, markPosition, markCode, trap_start_date,
             trap_end_date)
  }else if (grepl("knights_landing_release.csv", new_path)){
    readr::read_csv(new_file) |>
      mutate(releaseSubSite = ifelse(releaseSubSite == "N/A", NA, releaseSubSite),
             appliedMarkColor = ifelse(appliedMarkColor == "Not applicable (n/a)", NA, appliedMarkColor),
             appliedMarkPosition = str_replace(appliedMarkPosition, ",", ":"))
  }else if (grepl("knights_landing_releasefish.csv", new_path)){
    readr::read_csv(new_file) |>
      mutate(releaseFishID = as.character(releaseFishID),
             releaseID = as.character(releaseID))
  }
  # Write updated data back to the temporary directory
  write_csv(trap_data, trap_file)
  write_csv(cleaned_data, new_file)
  setwd(temp_dir)
  files_to_zip <- list.files(pattern = "^knights_landing", recursive = TRUE)

  zip(
    zipfile = file.path(original_wd, folder_path),
    files =  files_to_zip
  )
  setwd(original_wd)

}
path <- sort(c("knights_landing_catch.csv",
               "knights_landing_release.csv",
               "knights_landing_recapture.csv",
               "knights_landing_releasefish.csv"))
               # "knights_landing_trap.csv"))
full_trap_path <- paste0("data/knights_landing.zip/", "knights_landing_trap.csv")
full_new_data_path <- paste0("data/knights_landing.zip/", path)

# Apply the function to all file pairs
mapply(clean_zip_data, full_trap_path, full_new_data_path)
