library(tidyverse)
library(knitr)
library(lubridate)
library(googleCloudStorageR)
library(Hmisc)

gcs_auth(json_file = Sys.getenv("GCS_AUTH_FILE"))
gcs_global_bucket(bucket = Sys.getenv("GCS_DEFAULT_BUCKET"))

gcs_get_object(object_name = "rst/CAMP/knights_landing/CAMP_Knights.mdb",
               bucket = gcs_get_global_bucket(),
               saveToDisk = here::here("data-raw","CAMP.mdb"),
               overwrite = TRUE)
knights_camp <- (here::here("data-raw", "CAMP.mdb"))

catch_raw <- mdb.get(knights_camp, tables = "CatchRaw")
trap_visit <- mdb.get(knights_camp, tables = "TrapVisit") %>%
  mutate(visitTime = as.POSIXct(visitTime),
         visitTime2 = as.POSIXct(visitTime2))
site_lu <- mdb.get(knights_camp, "Site") %>%
  select(siteName, siteID)
subsite_lu <- mdb.get(knights_camp, "SubSite") %>%
  select(subSiteName, subSiteID, siteID) %>%
  filter(subSiteName != "N/A")
release <- mdb.get(knights_camp, tables = "Release") %>%
  mutate(releaseTime = as.POSIXct(releaseTime))
release_fish <- mdb.get(knights_camp, tables = "ReleaseFish")
mark_applied <- mdb.get(knights_camp, tables = "MarkApplied")
mark <-  mdb.get(knights_camp, tables = "MarkExisting")
environmental <- mdb.get(knights_camp, tables = "EnvDataRaw")

# Format trap table for EDI
trap_visit_format <- trap_visit %>%
  select(projectDescriptionID, trapVisitID, trapPositionID, visitTime, visitTime2,
         visitTypeID, fishProcessedID, inThalwegID, trapFunctioningID, counterAtStart,
         counterAtEnd, rpmRevolutionsAtStart, rpmSecondsAtStart, rpmRevolutionsAtEnd,
         rpmSecondsAtEnd, halfConeID, includeCatchID, debrisVolumeCatID, debrisVolume,
         debrisVolumeUnits) %>%
  left_join(subsite_lu, by = c("trapPositionID" = "subSiteID")) %>%
  select(-subSiteName) %>%
  relocate(siteID, .before = trapPositionID)

write_csv(trap_visit_format, here::here("data", "trap.csv"))

# Format catch table for EDI
catch_format <- catch_raw %>%
  select(projectDescriptionID, catchRawID, trapVisitID, taxonID, atCaptureRunID,
         atCaptureRunMethodID, finalRunID, finalRunMethodID, fishOriginID,
         lifeStageID, forkLength, totalLength, weight, n, randomID, actualCountID,
         releaseID, mortID) %>%
  left_join(trap_visit_format %>%
              select(projectDescriptionID, trapVisitID, visitTime, visitTime2, visitTypeID, siteID, trapPositionID),
            by = c("trapVisitID" = "trapVisitID", "projectDescriptionID" = "projectDescriptionID")) %>%
  relocate(releaseID, .before = taxonID)

write_csv(catch_format, here::here("data", "catch.csv"))

# Format release table for EDI
release_format <- release %>%
  select(projectDescriptionID, releaseID, releasePurposeID, markedTaxonID,
         markedRunID, markedLifeStageID, markedFishOriginID, sourceOfFishSiteID,
         releaseSiteID, releaseSubSiteID, nMortWhileHandling, nMortAtCheck,
         nReleased, releaseTime, releaseLightConditionID,
         testDays, includeTestID) %>%
  left_join(mark_applied %>%
              select(projectDescriptionID, releaseID, appliedMarkTypeID, appliedMarkColorID, appliedMarkPositionID, appliedMarkCode),
            by = c("projectDescriptionID" = "projectDescriptionID", "releaseID" = "releaseID"))
write_csv(release_format, here::here("data", "release.csv"))

# Format release fish table for EDI
release_fish_format <- release_fish %>%
  select(projectDescriptionID, releaseFishID, releaseID, nMarked, forkLength, weight)

write_csv(release_fish_format, here::here("data", "release_fish.csv"))

# Format for mark existing table for EDI
mark_existing_format <- mark %>%
  select(projectDescriptionID, catchRawID, markExistingID, markTypeID, markColorID, markPositionID, markCode)
write_csv(mark_existing_format, here::here("data", "mark_existing.csv"))

# Format for environmental table for EDI
environmental_format <- environmental %>%
  select(projectDescriptionID, envDataRawID, trapVisitID, discharge, dischargeUnitID, dischargeSampleGearID, waterVel, waterVelUnitID,
         waterVelSampleGearID, waterTemp, waterTempUnitID, waterTempSampleGearID, lightPenetration, lightPenetrationUnitID, lightPenetrationSampleGearID,
         turbidity, turbidityUnitID, turbiditySampleGearID) %>%
  left_join(trap_visit_format %>%
              select(projectDescriptionID, trapVisitID, visitTime, visitTime2, visitTypeID, siteID, trapPositionID),
            by = c("trapVisitID" = "trapVisitID", "projectDescriptionID" = "projectDescriptionID"))
write_csv(environmental_format, here::here("data", "environmental.csv"))
