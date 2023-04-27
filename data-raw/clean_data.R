library(tidyverse)
library(knitr)
library(lubridate)
library(googleCloudStorageR)
library(Hmisc)

# metadata notes
# TODO overall: do we want characters or codes in the clean data files?
# TODO overall: and do we want to list levels in the definition? way more for KNL than for others
# TODO catch metadata table has all taxon ID codes listed in definitions - keep?
# TODO trap metadata has all code definitions in definitions (siteID, halfConeID, etc.) - keep?
# TODO release metadata has all taxon ID in definitions
# TODO environmental metadata has all code IDs in definitions
# TODO markexisting metadata has all code IDs in definitions
# read in db --------------------------------------------------------------

# TODO do we want to upload the .mdb to google cloud and then pull in here,
# save to disk, and then read?
mdb.get(here::here("data-raw", "CAMP.mdb"), tables = TRUE)

catch_raw <- mdb.get(here::here("data-raw", "CAMP.mdb"), "CatchRaw") |>
  glimpse()

trap_raw <- mdb.get(here::here("data-raw", "CAMP.mdb"), "TrapVisit") |>
  glimpse()

release_raw <- mdb.get(here::here("data-raw", "CAMP.mdb"), "Release") |>
  mutate(releaseTime = as.POSIXct(releaseTime)) |>
  glimpse()

releasefish_raw <- mdb.get(here::here("data-raw", "CAMP.mdb"), "ReleaseFish") |>
  glimpse()

# lookups
site_lu <- mdb.get(here::here("data-raw", "CAMP.mdb"), "Site") |>
  select(siteName, siteID) |>  glimpse()
subsite_lu <- mdb.get(here::here("data-raw", "CAMP.mdb"), "SubSite") |>
  select(subSiteName, subSiteID, siteID) |>
  filter(subSiteName != "N/A") |>
  glimpse()

# other
mark_applied <- mdb.get(here::here("data-raw", "CAMP.mdb"), "MarkApplied")
mark_existing_raw <- mdb.get(here::here("data-raw", "CAMP.mdb"), "MarkExisting")
environmental_raw <- mdb.get(here::here("data-raw", "CAMP.mdb"), "EnvDataRaw")


# clean up and format data tables -----------------------------------------

# TODO debrisVolume and debrisVolumeUnits are NAs
# TODO do we want to keep includeCatchID?
# TODO what is debrisVolumeCatID?
trap <- trap_raw |>
  select(projectDescriptionID, trapVisitID, trapPositionID, visitTime, visitTime2,
         visitTypeID, fishProcessedID, inThalwegID, trapFunctioningID, counterAtStart,
         counterAtEnd, rpmRevolutionsAtStart, rpmSecondsAtStart, rpmRevolutionsAtEnd,
         rpmSecondsAtEnd, halfConeID, includeCatchID, debrisVolumeCatID, debrisVolume,
         debrisVolumeUnits) |>
  left_join(subsite_lu, by = c("trapPositionID" = "subSiteID")) |>
  select(-subSiteName) |>
  mutate(visitTime = as.POSIXct(visitTime),
         visitTime2 = as.POSIXct(visitTime2)) |>
  relocate(siteID, .before = trapPositionID) |>
  glimpse()

# TODO do we want to keep mortID?
# TODO do we want to keep actualCountID?
# TODO do we want to use lookup tables to get character values for mortID,
# fishOriginID, finalRunMethodID, finalRunID, atCaptureRunID, atCaptureRunMethodID,
# lifestageID?
catch <- catch_raw |>
  select(projectDescriptionID, catchRawID, trapVisitID, taxonID, atCaptureRunID,
         atCaptureRunMethodID, finalRunID, finalRunMethodID, fishOriginID,
         lifeStageID, forkLength, totalLength, weight, n, randomID, actualCountID,
         releaseID, mortID) |>
  left_join(trap |>
              select(projectDescriptionID, trapVisitID, visitTime,
                     visitTime2, visitTypeID, siteID, trapPositionID),
            by = c("trapVisitID", "projectDescriptionID")) |>
  relocate(releaseID, .before = taxonID) |>
  glimpse()

# TODO same question as catch - which IDs do we want character values for (i.e. pull in lookup tables),
# and which are ok to leave as IDs?
# TODO appliedMarkCode is empty right now
# TODO keep nMortAtCheck and nMortWhileHandling?
release <- release_raw |>
  select(projectDescriptionID, releaseID, releasePurposeID, markedTaxonID,
         markedRunID, markedLifeStageID, markedFishOriginID, sourceOfFishSiteID,
         releaseSiteID, releaseSubSiteID, nMortWhileHandling, nMortAtCheck,
         nReleased, releaseTime, releaseLightConditionID,
         testDays, includeTestID) |>
  left_join(mark_applied |>
              select(projectDescriptionID, releaseID, appliedMarkTypeID,
                     appliedMarkColorID, appliedMarkPositionID, appliedMarkCode),
            by = c("projectDescriptionID", "releaseID")) |>
  glimpse()

releasefish <- releasefish_raw |>
  select(projectDescriptionID, releaseFishID, releaseID, nMarked, forkLength, weight) |>
  glimpse()

# other tables
# TODO do we still want these?
mark_existing <- mark_existing_raw |>
  select(projectDescriptionID, catchRawID, markExistingID, markTypeID,
         markColorID, markPositionID, markCode) |>
  mutate(markCode = ifelse(markCode == "", NA_character_, markCode)) |>
  glimpse()

environmental <- environmental_raw |>
  select(projectDescriptionID, envDataRawID, trapVisitID, discharge, dischargeUnitID, dischargeSampleGearID, waterVel, waterVelUnitID,
         waterVelSampleGearID, waterTemp, waterTempUnitID, waterTempSampleGearID, lightPenetration, lightPenetrationUnitID, lightPenetrationSampleGearID,
         turbidity, turbidityUnitID, turbiditySampleGearID) |>
  left_join(trap |>
              select(projectDescriptionID, trapVisitID, visitTime,
                     visitTime2, visitTypeID, siteID, trapPositionID),
            by = c("trapVisitID", "projectDescriptionID")) |>
  glimpse()

# write clean tables ------------------------------------------------------

write_csv(trap, here::here("data", "trap.csv"))
write_csv(catch, here::here("data", "catch.csv"))
write_csv(release, here::here("data", "release.csv"))
write_csv(releasefish, here::here("data", "releasefish.csv"))
write_csv(mark_existing, here::here("data", "markexisting.csv"))
write_csv(environmental, here::here("data", "environmental.csv"))
