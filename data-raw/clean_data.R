library(tidyverse)
library(knitr)
library(lubridate)

# metadata notes

catch_raw <- readxl::read_xlsx(here::here("data-raw",
                                          "qry_Knights_CatchRaw_EDI.xlsx")) |>
  mutate(run = ifelse(run %in% c("Not applicable (n/a)", "Not recorded"), NA, run)) |>
  glimpse()

trap_raw <- readxl::read_xlsx(here::here("data-raw",
                                          "qry_Knights_TrapVisit_EDI.xlsx")) |>
  glimpse()

recaptures_raw <- readxl::read_xlsx(here::here("data-raw",
                                         "qry_Knights_Recaptures_EDI.xlsx")) |>
  mutate(run = ifelse(run %in% c("Not applicable (n/a)", "Not recorded"), NA, run)) |>
  glimpse()

release_raw <- readxl::read_xlsx(here::here("data-raw",
                                         "qry_Knights_Release_EDI.xlsx")) |>
  mutate(releaseSubSite = ifelse(releaseSubSite == "N/A", NA, releaseSubSite),
         appliedMarkColor = ifelse(appliedMarkColor == "Not applicable (n/a)", NA, appliedMarkColor)) |>
  glimpse()

release_fish_raw <- readxl::read_xlsx(here::here("data-raw",
                                         "qry_Knights_ReleaseFish_EDI.xlsx")) |>
  glimpse()

# write clean tables ------------------------------------------------------

write_csv(trap_raw, here::here("data", "trap.csv"))
write_csv(catch_raw, here::here("data", "catch.csv"))
write_csv(release_raw, here::here("data", "release.csv"))
write_csv(release_fish_raw, here::here("data", "release_fish.csv"))
write_csv(recaptures_raw, here::here("data", "recaptures.csv"))


# read in clean tables ----------------------------------------------------

catch <- read.csv(here::here("data", "catch.csv")) |> glimpse()
trap <- read.csv(here::here("data", "trap.csv")) |> glimpse()
release <- read.csv(here::here("data", "release.csv")) |> glimpse()
recaptures <- read.csv(here::here("data", "recaptures.csv")) |> glimpse()
release_fish <- read.csv(here::here("data", "release_fish.csv")) |> glimpse()
