library(tidyverse)
library(knitr)
library(lubridate)

# metadata notes

catch_raw <- readxl::read_xlsx(here::here("data-raw",
                                          "qry_Knights_CatchRaw_EDI.xlsx")) |>
  mutate(run = ifelse(run %in% c("Not applicable (n/a)", "Not recorded"), NA, run)) |>
  arrange(subSiteName, visitTime) |>
  mutate(trap_start_date = case_when(visitType %in% c("Continue trapping", "Unplanned restart", "End trapping") ~ lag(visitTime2),
                                     T ~ visitTime),
         trap_end_date = case_when(visitType %in% c("Continue trapping", "Unplanned restart", "End trapping") ~ visitTime,
                                   T ~ visitTime2)) |>
  glimpse()

trap_raw <- readxl::read_xlsx(here::here("data-raw",
                                          "qry_Knights_TrapVisit_EDI.xlsx")) |>
  arrange(subSiteName, visitTime) |>
  mutate(trap_start_date = case_when(visitType %in% c("Continue trapping", "Unplanned restart", "End trapping") ~ lag(visitTime2),
                                     T ~ visitTime),
         trap_end_date = case_when(visitType %in% c("Continue trapping", "Unplanned restart", "End trapping") ~ visitTime,
                                   T ~ visitTime2)) |>
  glimpse()

recaptures_raw <- readxl::read_xlsx(here::here("data-raw",
                                         "qry_Knights_Recaptures_EDI.xlsx")) |>
  mutate(run = ifelse(run %in% c("Not applicable (n/a)", "Not recorded"), NA, run)) |>
  glimpse()

release_raw <- readxl::read_xlsx(here::here("data-raw",
                                         "qry_Knights_Release_EDI.xlsx")) |>
  mutate(releaseSubSite = ifelse(releaseSubSite == "N/A", NA, releaseSubSite),
         appliedMarkColor = ifelse(appliedMarkColor == "Not applicable (n/a)", NA, appliedMarkColor),
         appliedMarkPosition = str_replace(appliedMarkPosition, ",", ":")) |>
  glimpse()

release_fish_raw <- readxl::read_xlsx(here::here("data-raw",
                                         "qry_Knights_ReleaseFish_EDI.xlsx")) |>
  glimpse()

# write clean tables ------------------------------------------------------

write_csv(trap_raw, here::here("data", "knights_trap_edi.csv"))
write_csv(catch_raw, here::here("data", "knights_catch_edi.csv"))
write_csv(release_raw, here::here("data", "knights_release_edi.csv"))
write_csv(release_fish_raw, here::here("data", "knights_release_fish_edi.csv"))
write_csv(recaptures_raw, here::here("data", "knights_recapture_edi.csv"))


# read in clean tables ----------------------------------------------------

catch <- read.csv(here::here("data", "knights_catch_edi.csv")) |> glimpse()
trap <- read.csv(here::here("data", "knights_trap_edi.csv")) |> glimpse()
release <- read.csv(here::here("data", "knights_release_edi.csv")) |> glimpse()
recaptures <- read.csv(here::here("data", "knights_recapture_edi.csv")) |> glimpse()
release_fish <- read.csv(here::here("data", "knights_release_fish_edi.csv")) |> glimpse()
