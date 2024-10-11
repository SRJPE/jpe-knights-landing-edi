library(tidyverse)
library(knitr)
library(lubridate)

# metadata notes

# catch ----

#EDI API code

# knights_tables <- read_data_entity_names(packageId = "edi.1501.1")
#  knights_tables
#
#  catch_raw <- read_data_entity(packageId = "edi.1501.1", entityId = knights_tables$entityId[2])
#  head(catch_raw)
#
#  catch_raw <- readr::read_csv(file = catch_raw)
#
#  catch_raw <- catch_raw |>
#    mutate(run = ifelse(run %in% c("Not applicable (n/a)", "Not recorded"), NA, run)) |>
#   arrange(subSiteName, visitTime) |>
#   mutate(trap_start_date = case_when(visitType %in% c("Continue trapping", "Unplanned restart", "End trapping") ~ lag(visitTime2),
#                                         T ~ visitTime),
#           trap_end_date = case_when(visitType %in% c("Continue trapping", "Unplanned restart", "End trapping") ~ visitTime,
#                                       T ~ visitTime2)) |>
#    glimpse()

catch_raw <- readxl::read_xlsx(here::here("data-raw", "qry_Knights_CatchRaw_EDI.xlsx")) |>
  mutate(run = ifelse(run %in% c("Not applicable (n/a)", "Not recorded"), NA, run)) |>
  arrange(subSiteName, visitTime) |>
  mutate(trap_start_date = ymd_hms(case_when(visitType %in% c("Continue trapping", "Unplanned restart", "End trapping") ~ lag(visitTime2),
                                     T ~ visitTime)),
         trap_end_date = ymd_hms(case_when(visitType %in% c("Continue trapping", "Unplanned restart", "End trapping") ~ visitTime,
                                   T ~ visitTime2))) |>
  glimpse()


# trap ----

#EDI API code

# trap_raw <- read_data_entity(packageId = "edi.1501.1", entityId = knights_tables$entityId[1])
# head(trap_raw)
#
# trap_raw <- readr::read_csv(file = trap_raw)
#
# trap_raw <- trap_raw |>
#   arrange(subSiteName, visitTime) |>
#   mutate(trap_start_date = case_when(visitType %in% c("Continue trapping", "Unplanned restart", "End trapping") ~ lag(visitTime2),
#                                        T ~ visitTime),
#          trap_end_date = case_when(visitType %in% c("Continue trapping", "Unplanned restart", "End trapping") ~ visitTime,
#                                      T ~ visitTime2)) |>
#   glimpse()

trap_raw <- readxl::read_xlsx(here::here("data-raw",
                                          "qry_Knights_TrapVisit_EDI.xlsx"),
                              col_types = c("numeric", "numeric","date","date","text","text","text","text","text",
                                            "numeric","numeric","numeric","numeric","text","numeric","numeric",
                                            "numeric","numeric","numeric","numeric","numeric")) |> # if don't specify col_type then dissolved oxygen and conductivity read as logical
  arrange(subSiteName, visitTime) |>
  mutate(trap_start_date = ymd_hms(case_when(visitType %in% c("Continue trapping", "Unplanned restart", "End trapping") ~ lag(visitTime2),
                                     T ~ visitTime)),
         trap_end_date = ymd_hms(case_when(visitType %in% c("Continue trapping", "Unplanned restart", "End trapping") ~ visitTime,
                                   T ~ visitTime2))) |>
  glimpse()



# recapture ---

recaptures_raw <- readxl::read_xlsx(here::here("data-raw",
                                         "qry_Knights_Recaptures_EDI.xlsx")) |>
  left_join(trap_raw |>
              select(trapVisitID, visitTime, visitTime2) |>
              distinct()) |>
  mutate(run = ifelse(run %in% c("Not applicable (n/a)", "Not recorded"), NA, run),
         trap_start_date = ymd_hms(case_when(visitType %in% c("Continue trapping", "Unplanned restart", "End trapping") ~ lag(visitTime2),
                                             T ~ visitTime)),
         trap_end_date = ymd_hms(case_when(visitType %in% c("Continue trapping", "Unplanned restart", "End trapping") ~ visitTime,
                                           T ~ visitTime2))) |>
  select(ProjectDescriptionID, catchRawID, trapVisitID, commonName, releaseID, run, fishOrigin, lifeStage, forkLength, n,
         visitTime, visitTime2, visitType, siteName, subSiteName, markType, markColor, markPosition, markCode, trap_start_date,
         trap_end_date) |>
  glimpse()

# release ---
release_raw <- readxl::read_xlsx(here::here("data-raw",
                                         "qry_Knights_Release_EDI.xlsx")) |>
  mutate(releaseSubSite = ifelse(releaseSubSite == "N/A", NA, releaseSubSite),
         appliedMarkColor = ifelse(appliedMarkColor == "Not applicable (n/a)", NA, appliedMarkColor),
         appliedMarkPosition = str_replace(appliedMarkPosition, ",", ":")) |>
  glimpse()

# release_raw ---
release_fish_raw <- readxl::read_xlsx(here::here("data-raw",
                                         "qry_Knights_ReleaseFish_EDI.xlsx")) |>
  mutate(releaseFishID = as.character(releaseFishID),
         releaseID = as.character(releaseID)) |>
  glimpse()

# write clean tables ------------------------------------------------------

write_csv(trap_raw, here::here("data", "knights_trap_edi.csv"))
write_csv(catch_raw, here::here("data", "knights_catch_edi.csv"))
write_csv(release_raw, here::here("data", "knights_release_edi.csv"))
write_csv(release_fish_raw, here::here("data", "knights_release_fish_edi.csv"))
write_csv(recaptures_raw, here::here("data", "knights_recapture_edi.csv"))


# read in clean tables ----------------------------------------------------

# catch <- read.csv(here::here("data", "knights_catch_edi.csv")) |> glimpse()
# trap <- read.csv(here::here("data", "knights_trap_edi.csv")) |> glimpse()
# release <- read.csv(here::here("data", "knights_release_edi.csv")) |> glimpse()
# recaptures <- read.csv(here::here("data", "knights_recapture_edi.csv")) |> glimpse()
# release_fish <- read.csv(here::here("data", "knights_release_fish_edi.csv")) |> glimpse()
