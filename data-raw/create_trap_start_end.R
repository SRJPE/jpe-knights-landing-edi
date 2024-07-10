# Test assigning trap start and stop date
library(tidyverse)
# In thetidyverse# In the CAMP db, visitTime and visitTime2 are defined by visitType
# visitType == "Start trap & begin trapping": visitTime "arrival at trap", visitTime2 trap start for following day
# visitType == "Continue trapping": visitTime: trap end for current day, visitTime2 trap start for following day
# visitType == "Unplanned restart": visitTime: trap end for current day, visitTime2 trap start for following day
# visitType == "End trapping": visitTime: trap end for current day, visitTime2 end of trap visit
# visitType == "Service/adjust/clean trap": VisitTime "arrival at trap", visitTime2 end of trap visit
# visitType == "Drive-by only": visitTime "arrival at trap", visitTime2 end of trap visit

# read in trap data
# if include this in EDI package could use API to download from package
# code is only applied to the trap data for testing. will also apply to catch data
trap_raw <- readxl::read_xlsx(here::here("data-raw",
                                         "qry_Knights_TrapVisit_EDI.xlsx")) |>
  glimpse()


# will need to note that trap_start and trap_end for "Start trap & begin trapping", "Service/adjust/clean trap", "Drive-by only" represent the visit start and stop
trap_start_end <- trap_raw |>
  select(projectDescriptionID, trapVisitID, siteName, subSiteName, visitTime, visitTime2, visitType) |>
  arrange(subSiteName, visitTime) |>
  mutate(trap_start_date = case_when(visitType %in% c("Continue trapping", "Unplanned restart", "End trapping") ~ lag(visitTime2),
                                T ~ visitTime),
         trap_end_date = case_when(visitType %in% c("Continue trapping", "Unplanned restart", "End trapping") ~ visitTime,
                              T ~ visitTime2))
# make sure none are less than 0
trap_start_end |>
  mutate(ck = trap_end_date - trap_start_date) |>
  filter(ck < 0)

write_csv(trap_start_end, "data-raw/test_trap_start_end.csv")
