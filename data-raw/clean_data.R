library(tidyverse)
library(knitr)
library(lubridate)
library(googleCloudStorageR)
library(Hmisc)

# metadata notes
# TODO overall: do we want characters or codes in the clean data file - i.e. join with LU tables?
# TODO overall: and do we want to list levels in the definition? way more for KNL than for others
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
active_lu <- mdb.get(here::here("data-raw", "CAMP.mdb"), "luActive") |>
  glimpse()
bodypart_lu <- mdb.get(here::here("data-raw", "CAMP.mdb"), "luBodyPart") |>
  filter(activeID != 2) |>
  select(-activeID) |>
  glimpse()
color_lu <- mdb.get(here::here("data-raw", "CAMP.mdb"), "luColor") |>
  filter(activeID != 2) |>
  select(-activeID) |>
  glimpse()
cone_debris_vol_cat_lu <- mdb.get(here::here("data-raw", "CAMP.mdb"), "luConeDebrisVolumeCat") |>
  filter(activeID != 2) |>
  select(-activeID) |>
  glimpse()
debris_vol_cat_lu <- mdb.get(here::here("data-raw", "CAMP.mdb"), "luDebrisVolumeCat") |>
  filter(activeID != 2) |>
  select(-activeID) |>
  glimpse()
fish_origin_lu <- mdb.get(here::here("data-raw", "CAMP.mdb"), "luFishOrigin") |>
  filter(activeID != 2) |>
  select(-activeID) |>
  glimpse()
lifestage_lu <- mdb.get(here::here("data-raw", "CAMP.mdb"), "luLifeStage") |>
  filter(activeID != 2) |>
  select(-c(activeID, lifeStageCAMPID)) |>
  glimpse()
lightcondition_lu <- mdb.get(here::here("data-raw", "CAMP.mdb"), "luLightCondition") |>
  filter(activeID != 2) |>
  select(-activeID) |>
  glimpse()
marktype_lu <- mdb.get(here::here("data-raw", "CAMP.mdb"), "luMarkType") |>
  filter(activeID != 2) |>
  select(-activeID) |>
  glimpse()
marktype_lu <- mdb.get(here::here("data-raw", "CAMP.mdb"), "luMarkType") |>
  filter(activeID != 2) |>
  select(-activeID) |>
  glimpse()
noyes_lu <- mdb.get(here::here("data-raw", "CAMP.mdb"), "luNoYes") |>
  glimpse()
release_purpose_lu <- mdb.get(here::here("data-raw", "CAMP.mdb"), "luReleasePurpose") |>
  filter(activeID != 2) |>
  select(-activeID) |>
  glimpse()
run_lu <- mdb.get(here::here("data-raw", "CAMP.mdb"), "luRun") |>
  filter(activeID != 2) |>
  select(-activeID) |>
  glimpse()
run_method_lu <- mdb.get(here::here("data-raw", "CAMP.mdb"), "luRunMethod") |>
  filter(activeID != 2) |>
  select(-activeID) |>
  glimpse()
sample_gear_lu <- mdb.get(here::here("data-raw", "CAMP.mdb"), "luSampleGear") |>
  filter(activeID != 2) |>
  select(-activeID) |>
  glimpse()
specimen_type_lu <- mdb.get(here::here("data-raw", "CAMP.mdb"), "luSpecimenType") |>
  filter(activeID != 2) |>
  select(-activeID) |>
  glimpse()
subsample_method_lu <- mdb.get(here::here("data-raw", "CAMP.mdb"), "luSubsampleMethod") |>
  filter(activeID != 2) |>
  select(-activeID) |>
  glimpse()
taxon_lu <- mdb.get(here::here("data-raw", "CAMP.mdb"), "luTaxon") |>
  filter(activeID != 2) |>
  select(taxonID, commonName) |>
  mutate(taxonID = as.numeric(taxonID)) |>
  glimpse()
trap_functioning_lu <- mdb.get(here::here("data-raw", "CAMP.mdb"), "luTrapFunctioning") |>
  filter(activeID != 2) |>
  select(-activeID) |>
  glimpse()
unit_lu <- mdb.get(here::here("data-raw", "CAMP.mdb"), "luUnit") |>
  filter(activeID != 2) |>
  select(-activeID) |>
  glimpse()
visit_type_lu <- mdb.get(here::here("data-raw", "CAMP.mdb"), "luVisitType") |>
  filter(activeID != 2) |>
  select(-activeID) |>
  glimpse()
agency_lu <- mdb.get(here::here("data-raw", "CAMP.mdb"), "luAgency") |>
  filter(activeID != 2) |>
  select(-activeID) |>
  glimpse()
fish_processed_lu <- mdb.get(here::here("data-raw", "CAMP.mdb"), "luFishProcessed") |>
  filter(activeID != 2) |>
  select(-activeID) |>
  glimpse()


# other
mark_applied <- mdb.get(here::here("data-raw", "CAMP.mdb"), "MarkApplied")
mark_existing_raw <- mdb.get(here::here("data-raw", "CAMP.mdb"), "MarkExisting")
environmental_raw <- mdb.get(here::here("data-raw", "CAMP.mdb"), "EnvDataRaw")


# clean up and format data tables -----------------------------------------

# TODO debrisVolume and debrisVolumeUnits are NAs
# TODO do we want to keep includeCatchID?
trap <- trap_raw |>
  select(projectDescriptionID, trapVisitID, trapPositionID, visitTime, visitTime2,
         visitTypeID, fishProcessedID, inThalwegID, trapFunctioningID, counterAtStart,
         counterAtEnd, rpmRevolutionsAtStart, rpmSecondsAtStart, rpmRevolutionsAtEnd,
         rpmSecondsAtEnd, halfConeID, includeCatchID, debrisVolumeCatID, debrisVolume,
         debrisVolumeUnits) |>
  left_join(subsite_lu, by = c("trapPositionID" = "subSiteID")) |>
  left_join(visit_type_lu, by = "visitTypeID") |>
  left_join(fish_processed_lu, by = "fishProcessedID") |>
  left_join(trap_functioning_lu, by = "trapFunctioningID") |>
  left_join(cone_debris_vol_cat_lu, by = "debrisVolumeCatID") |>
  left_join(noyes_lu, by = c("includeCatchID" = "noYesID")) |>
  rename(includeCatch = noYes) |>
  left_join(noyes_lu, by = c("halfConeID" = "noYesID")) |>
  rename(halfCone = noYes) |>
  select(-c(subSiteName, fishProcessedID,
            trapFunctioningID, debrisVolumeCatID,
            includeCatchID, halfConeID)) |>
  mutate(visitTime = as.POSIXct(visitTime),
         visitTime2 = as.POSIXct(visitTime2)) |>
  relocate(siteID, .before = trapPositionID) |>
  glimpse()

# TODO do we want to keep actualCountID?

catch <- catch_raw |>
  select(projectDescriptionID, catchRawID, trapVisitID, taxonID, atCaptureRunID,
         atCaptureRunMethodID, finalRunID, finalRunMethodID, fishOriginID,
         lifeStageID, forkLength, totalLength, weight, n, randomID, actualCountID,
         releaseID) |>
  left_join(trap |>
              select(projectDescriptionID, trapVisitID, visitTime,
                     visitTime2, visitTypeID, siteID, trapPositionID),
            by = c("trapVisitID", "projectDescriptionID")) |>
  left_join(visit_type_lu, by = "visitTypeID") |>
  left_join(taxon_lu, by = "taxonID") |>
  left_join(run_lu, by = c("atCaptureRunID" = "runID")) |>
  left_join(run_method_lu, by = c("atCaptureRunMethodID" = "runMethodID")) |>
  rename(atCaptureRun = run, atCaptureRunMethod = runMethod) |>
  left_join(run_method_lu, by = c("finalRunMethodID" = "runMethodID")) |>
  left_join(run_lu, by = c("finalRunID" = "runID")) |>
  rename(finalRun = run, finalRunMethod = runMethod) |>
  left_join(fish_origin_lu, by = "fishOriginID") |>
  left_join(lifestage_lu, by = "lifeStageID") |>
  left_join(noyes_lu, by = c("actualCountID" = "noYesID")) |>
  rename(actualCount = noYes) |>
  left_join(noyes_lu, by = c("randomID" = "noYesID")) |>
  rename(random = noYes) |>
  #relocate(releaseID, .before = commonName) |>
  select(-c(visitTypeID, taxonID, atCaptureRunID, atCaptureRunMethodID,
            finalRunMethodID, finalRunID, fishOriginID, lifeStageID,
            actualCountID, randomID)) |>
  glimpse()

release <- release_raw |>
  select(projectDescriptionID, releaseID, releasePurposeID, markedTaxonID,
         markedRunID, markedLifeStageID, markedFishOriginID, sourceOfFishSiteID,
         releaseSiteID, releaseSubSiteID,
         nReleased, releaseTime, releaseLightConditionID,
         testDays, includeTestID) |>
  left_join(mark_applied |>
              select(projectDescriptionID, releaseID, appliedMarkTypeID,
                     appliedMarkColorID, appliedMarkPositionID),
            by = c("projectDescriptionID", "releaseID")) |>
  left_join(release_purpose_lu, by = c("releasePurposeID" = "releasePursposeID")) |>
  left_join(taxon_lu, by = c("markedTaxonID" = "taxonID")) |>
  left_join(run_lu, by = c("markedRunID" = "runID")) |>
  left_join(lifestage_lu, by = c("markedLifeStageID" = "lifeStageID")) |>
  left_join(fish_origin_lu, by = c("markedFishOriginID" = "fishOriginID")) |>
  left_join(lightcondition_lu, by = c("releaseLightConditionID" = "lightConditionID")) |>
  left_join(noyes_lu, by = c("includeTestID" = "noYesID")) |>
  rename(includeTest = noYes) |>
  left_join(marktype_lu, by = c("appliedMarkTypeID" = "markTypeID")) |>
  left_join(color_lu, by = c("appliedMarkColorID" = "colorID")) |>
  rename(markedRun = run, markedLifeStage = lifeStage,
         markedFishOrigin = fishOrigin,
         releaseLightCondition = lightCondition,
         appliedMarkType = markType, appliedMarkColor = color) |>
  select(-c(releasePurposeID, markedTaxonID, markedRunID, markedLifeStageID,
            markedFishOriginID, releaseLightConditionID, includeTestID,
            appliedMarkTypeID, appliedMarkColorID)) |>
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
  left_join(marktype_lu, by = c("markTypeID" = "markTypeID")) |>
  left_join(color_lu, by = c("markColorID" = "colorID")) |>
  rename(markColor = color) |>
  select(-c(markTypeID, markColorID)) |>
  glimpse()

environmental <- environmental_raw |>
  select(projectDescriptionID, envDataRawID, trapVisitID, discharge, dischargeUnitID, dischargeSampleGearID, waterVel, waterVelUnitID,
         waterVelSampleGearID, waterTemp, waterTempUnitID, waterTempSampleGearID, lightPenetration, lightPenetrationUnitID, lightPenetrationSampleGearID,
         turbidity, turbidityUnitID, turbiditySampleGearID) |>
  left_join(trap |>
              select(projectDescriptionID, trapVisitID, visitTime,
                     visitTime2, visitTypeID, siteID, trapPositionID),
            by = c("trapVisitID", "projectDescriptionID")) |>
  left_join(unit_lu, by = c("dischargeUnitID" = "unitID")) |>
  rename(dischargeUnit = unit) |>
  left_join(unit_lu, by = c("waterVelUnitID" = "unitID")) |>
  rename(waterVelUnit = unit) |>
  left_join(unit_lu, by = c("waterTempUnitID" = "unitID")) |>
  rename(waterTempUnit = unit) |>
  left_join(unit_lu, by = c("lightPenetrationUnitID" = "unitID")) |>
  rename(lightPenetrationUnit = unit) |>
  left_join(unit_lu, by = c("turbidityUnitID" = "unitID")) |>
  rename(turbidityUnit = unit) |>
  left_join(sample_gear_lu, by = c("dischargeSampleGearID" = "sampleGearID")) |>
  rename(dischargeSampleGear = sampleGear) |>
  left_join(sample_gear_lu, by = c("waterVelSampleGearID" = "sampleGearID")) |>
  rename(waterVelSampleGear = sampleGear) |>
  left_join(sample_gear_lu, by = c("waterTempSampleGearID" = "sampleGearID")) |>
  rename(waterTempSampleGear = sampleGear) |>
  left_join(sample_gear_lu, by = c("lightPenetrationSampleGearID" = "sampleGearID")) |>
  rename(lightPenetrationSampleGear = sampleGear) |>
  left_join(sample_gear_lu, by = c("turbiditySampleGearID" = "sampleGearID")) |>
  rename(turbiditySampleGear = sampleGear) |>
  select(-c(dischargeUnitID, waterVelUnitID, waterTempUnitID, lightPenetrationUnitID,
            turbidityUnitID, dischargeSampleGearID, waterVelSampleGearID,
            waterTempSampleGearID, lightPenetrationSampleGearID, turbiditySampleGearID)) |>
  glimpse()

trap <- trap |> select(-visitTypeID) # remove ID column after joins

# write clean tables ------------------------------------------------------

write_csv(trap, here::here("data", "trap.csv"))
write_csv(catch, here::here("data", "catch.csv"))
write_csv(release, here::here("data", "release.csv"))
write_csv(releasefish, here::here("data", "releasefish.csv"))
write_csv(mark_existing, here::here("data", "markexisting.csv"))
write_csv(environmental, here::here("data", "environmental.csv"))
