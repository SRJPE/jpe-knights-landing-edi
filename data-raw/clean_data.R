library(tidyverse)
library(knitr)
library(lubridate)

# metadata notes

catch_raw <- readxl::read_xlsx(here::here("data-raw",
                                          "qry_Knights_CatchRaw_EDI.xlsx")) |>
  glimpse()

trap_raw <- readxl::read_xlsx(here::here("data-raw",
                                          "qry_Knights_TrapVisit_EDI.xlsx")) |>
  glimpse()

recaptures_raw <- readxl::read_xlsx(here::here("data-raw",
                                         "qry_Knights_Recaptures_EDI.xlsx")) |>
  glimpse()

release_raw <- readxl::read_xlsx(here::here("data-raw",
                                         "qry_Knights_Release_EDI.xlsx")) |>
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
