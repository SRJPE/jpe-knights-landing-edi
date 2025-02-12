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

clean_current_year_data <- function(trap_path, new_path) {
  trap_data <- readr::read_csv(trap_path, col_type = list(
    projectDescriptionID = col_double(),
    trapVisitID = col_double(),
    visitTime = col_datetime(format = ""),
    visitTime2 = col_datetime(format = ""),
    siteName = col_character(),
    subSiteName = col_double(),
    visitType = col_character(),
    fishProcessed = col_character(),
    trapFunctioning = col_character(),
    counterAtStart = col_double(),
    counterAtEnd = col_double(),
    rpmRevolutionsAtStart = col_double(),
    rpmRevolutionsAtEnd = col_double(),
    includeCatch = col_character(),
    discharge = col_double(),
    waterVel = col_double(),
    waterTemp = col_double(),
    lightPenetration = col_double(),
    turbidity = col_double(),
    dissolvedOxygen = col_double(),
    conductivity = col_double()
  )) |>
    arrange(subSiteName, visitTime) |>
    mutate(trap_start_date = ymd_hms(case_when(visitType %in% c("Continue trapping", "Unplanned restart", "End trapping") ~ lag(visitTime2),
                                               T ~ visitTime)),
           trap_end_date = ymd_hms(case_when(visitType %in% c("Continue trapping", "Unplanned restart", "End trapping") ~ visitTime,
                                             T ~ visitTime2)))

  cleaned_data <- if (grepl("current_year_knights_landing_catch.csv", new_path)) {
    readr::read_csv(new_path, col_type = list(
      ProjectDescriptionID = col_double(),
      trapVisitID = col_double(),
      visitTime = col_datetime(format = ""),
      visitTime2 = col_datetime(format = ""),
      siteName = col_character(),
      subSiteName = col_double(),
      visitType = col_character(),
      catchRawID = col_double(),
      commonName = col_character(),
      releaseID = col_double(),
      run = col_character(),
      fishOrigin = col_character(),
      lifeStage = col_character(),
      forkLength = col_double(),
      totalLength = col_double(),
      weight = col_double(),
      n = col_double()
    )) |>
      mutate(run = ifelse(run %in% c("Not applicable (n/a)", "Not recorded"), NA, run)) |>
      arrange(subSiteName, visitTime) |>
      left_join(trap_data |>
                  select(trapVisitID, trap_start_date, trap_end_date))
  }else if(grepl("current_year_knights_landing_recapture.csv", new_path)) {
    readr::read_csv(new_path, col_type = list(
      ProjectDescriptionID = col_double(),
      catchRawID = col_double(),
      trapVisitID = col_double(),
      commonName = col_character(),
      releaseID = col_double(),
      run = col_character(),
      fishOrigin = col_character(),
      lifeStage = col_character(),
      forkLength = col_double(),
      n = col_double(),
      visitTime = col_datetime(format = ""),
      visitType = col_character(),
      siteName = col_character(),
      subSiteName = col_double(),
      markType = col_character(),
      markColor = col_character(),
      markPosition = col_character(),
      markCode = col_logical()
    )) |>
      left_join(trap_data |>
                  select(trapVisitID, visitTime, visitTime2, trap_start_date, trap_end_date) |>
                  distinct()) |>
      mutate(run = ifelse(run %in% c("Not applicable (n/a)", "Not recorded"), NA, run)) |>
      select(ProjectDescriptionID, catchRawID, trapVisitID, commonName, releaseID, run, fishOrigin, lifeStage, forkLength, n,
             visitTime, visitTime2, visitType, siteName, subSiteName, markType, markColor, markPosition, markCode, trap_start_date,
             trap_end_date)
  }else if (grepl("current_year_knights_landing_release.csv", new_path)){
    readr::read_csv(new_path, col_types = list(
      projectDescriptionID = col_double(),
      releaseID = col_double(),
      releaseTime = col_datetime(format = ""),
      commonName = col_character(),
      markedRun = col_character(),
      markedLifeStage = col_character(),
      markedFishOrigin = col_character(),
      sourceOfFishSite = col_character(),
      releaseSite = col_character(),
      releaseSubSite = col_character(),
      nReleased = col_double(),
      testDays = col_double(),
      appliedMarkType = col_character(),
      appliedMarkColor = col_character(),
      appliedMarkPosition = col_character(),
      IncludeInAnalysis = col_character()
    )) |>
      mutate(releaseSubSite = ifelse(releaseSubSite == "N/A", NA, releaseSubSite),
             appliedMarkColor = ifelse(appliedMarkColor == "Not applicable (n/a)", NA, appliedMarkColor),
             appliedMarkPosition = str_replace(appliedMarkPosition, ",", ":"))
  }else if (grepl("current_year_knights_landing_releasefish.csv", new_path)){
    readr::read_csv(new_path,col_types = list(
      projectDescriptionID = col_double(),
      releaseFishID = col_double(),
      releaseID = col_double(),
      forkLength = col_double()
    )) |>
      mutate(releaseFishID = as.character(releaseFishID),
             releaseID = as.character(releaseID))
  }
  write_csv(trap_data, trap_path)
  write_csv(cleaned_data, new_path)
}

path <- sort(c("knights_landing_catch.csv",
               "knights_landing_release.csv",
               "knights_landing_recapture.csv",
               "knights_landing_releasefish.csv"))
               # "knights_landing_trap.csv"))
full_trap_path <- paste0("data/knights_landing.zip/", "knights_landing_trap.csv")
full_new_data_path <- paste0("data/knights_landing.zip/", path)
mapply(clean_zip_data, full_trap_path, full_new_data_path)

current_year_path <- sort(c("data/current_year_knights_landing_catch.csv",
                            "data/current_year_knights_landing_release.csv",
                            "data/current_year_knights_landing_recapture.csv",
                            "data/current_year_knights_landing_releasefish.csv"))
current_year_trap_path <- "data/current_year_knights_landing_trap.csv"
mapply(clean_current_year_data, current_year_trap_path, current_year_path)


