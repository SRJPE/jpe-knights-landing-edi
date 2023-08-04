library(EMLaide)
library(tidyverse)
library(readxl)
library(EML)

datatable_metadata <-
  dplyr::tibble(filepath = c("data/trap.csv",
                             "data/catch.csv",
                             "data/recaptures.csv",
                             "data/release_fish.csv",
                             "data/release.csv"),
                attribute_info = c("data-raw/metadata/trap_metadata.xlsx",
                                   "data-raw/metadata/catch_metadata.xlsx",
                                   "data-raw/metadata/recaptures_metadata.xlsx",
                                   "data-raw/metadata/release_fish_metadata.xlsx",
                                   "data-raw/metadata/release_metadata.xlsx"),
                datatable_description = c("Daily trap operations",
                                          "Daily catch",
                                          "Recaptured catch",
                                          "Release fish measurements",
                                          "Release trial summary"),
                datatable_url = paste0("https://raw.githubusercontent.com/SRJPE/jpe-knights-edi/main/data/",
                                       c("trap.csv",
                                         "catch.csv",
                                         "recaptures.csv",
                                         "release_fish.csv",
                                         "release.csv")))
# save cleaned data to `data/`
excel_path <- "data-raw/metadata/KDL_project_metadata.xlsx"
sheets <- readxl::excel_sheets(excel_path)
metadata <- lapply(sheets, function(x) readxl::read_excel(excel_path, sheet = x))
names(metadata) <- sheets

abstract_docx <- "data-raw/metadata/abstract.docx"
methods_docx <- "data-raw/metadata/methods.md"

#edi_number <- reserve_edi_id(user_id = Sys.getenv("EDI_USER_ID"), password = Sys.getenv("EDI_PASSWORD"))
edi_number <- "edi.1243.1"

dataset <- list() %>%
  add_pub_date() %>%
  add_title(metadata$title) %>%
  add_personnel(metadata$personnel) %>%
  add_keyword_set(metadata$keyword_set) %>%
  add_abstract(abstract_docx) %>%
  add_license(metadata$license) %>%
  add_method(methods_docx) %>%
  add_maintenance(metadata$maintenance) %>%
  add_project(metadata$funding) %>%
  add_coverage(metadata$coverage, metadata$taxonomic_coverage) %>%
  add_datatable(datatable_metadata)

# GO through and check on all units
custom_units <- data.frame(id = c("count of fish", "Nephelometric Turbidity Units (NTU)", "day", "number of rotations",
                                  "revolutions per minute", "microSiemens per centimeter"),
                           unitType = c("dimensionless", "dimensionless", "dimensionless",
                                        "dimensionless", "dimensionless", "dimensionless"),
                           parentSI = c(NA, NA, NA, NA, NA, NA),
                           multiplierToSI = c(NA, NA, NA, NA, NA, NA),
                           description = c("Count of fish",
                                           "Unit of measurement for turbidity",
                                           "Number of days",
                                           "Total rotations",
                                           "Number of revolutions per minute",
                                           "Unit of measurement for conductivity"))

unitList <- EML::set_unitList(custom_units)

eml <- list(packageId = edi_number,
            system = "EDI",
            access = add_access(),
            dataset = dataset,
            additionalMetadata = list(metadata = list(unitList = unitList))
)

EML::write_eml(eml, "edi.1243.1.xml")
EML::eml_validate("edi.1243.1.xml")

# EMLaide::evaluate_edi_package(Sys.getenv("user_ID"), Sys.getenv("password"), "edi.1047.1.xml")
# EMLaide::upload_edi_package(Sys.getenv("user_ID"), Sys.getenv("password"), "edi.1047.1.xml")
# doc <- read_xml("edi.1243.1.xml")
# edi_number<- data.frame(edi_number = doc %>% xml_attr("packageId"))
# update_number <- edi_number %>%
#   separate(edi_number, c("edi","package","version"), "\\.") %>%
#   mutate(version = as.numeric(version) + 1)
# edi_number <- paste0(update_number$edi, ".", update_number$package, ".", update_number$version)

# preview_coverage <- function(dataset) {
#   coords <- dataset$coverage$geographicCoverage$boundingCoordinates
#   north <- coords$northBoundingCoordinate
#   south <- coords$southBoundingCoordinate
#   east <- coords$eastBoundingCoordinate
#   west <- coords$westBoundingCoordinate
#
#   leaflet::leaflet() |>
#     leaflet::addTiles() |>
#     leaflet::addRectangles(
#       lng1 = west, lat1 = south,
#       lng2 = east, lat2 = north,
#       fillColor = "blue"
#     )
# }

preview_coverage(dataset)
