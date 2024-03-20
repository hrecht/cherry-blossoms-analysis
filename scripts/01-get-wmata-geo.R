# Get data on WMATA stations

library(jsonlite)
library(dplyr)
library(tidyr)
library(sf)
library(janitor)
library(stringr)
library(ggplot2)

######################################################################################
# Use regional stations list from DC Open Data to match route lines from them
# https://opendata.dc.gov/datasets/DCGIS::metro-stations-regional/about
# There are some errors/outdated line info to correct
# Also for charting use short version of the names from latest WMATA map
######################################################################################
stations_raw <- read.csv("data/original/Metro_Stations_Regional.csv")
stations_raw <- clean_names(stations_raw)
colnames(stations_raw)

stations <- stations_raw %>% select(latitude = y, longitude = x,
																		name, address, line, mar_id, objectid)

# Split out state
# Formatting is inconsistent so separate function not working well
stations <- stations %>% mutate(state = case_when(
	str_detect(address, ", DC") ~ "DC",
	str_detect(address, ", MD") ~ "MD",
	str_detect(address, ", VA") ~ "VA"
))
stations %>% count(state)

stations %>% count(line)

######################################################################################
# Read in corrections
# I entered corrected lines and split out the main name plus subtitle name based
# on the latest rail map and station list on WMATA's website
# Open data file had a bunch of outdated or wrong info though locations look right
######################################################################################
stations_corrections <- read.csv("data/metro/metro-stations-corrections.csv")

# Correct lines and add in short display names
stations <- left_join(stations, stations_corrections, by = c("name" = "NAME", "line" = "LINE"))
stations <- stations %>% mutate(line = ifelse(line_correct != "", line_correct, line))

stations <- stations %>% mutate(name_short = ifelse(name_short == "", name, name_short))
stations <- stations %>% select(-line_correct) %>%
	select(name_short, name_subtitle, name, state, everything())

# Make a binary for each line
stations <- stations %>% mutate(
	line_rd = ifelse(str_detect(line, "red"), 1, 0),
	line_or = ifelse(str_detect(line, "orange"), 1, 0),
	line_sv = ifelse(str_detect(line, "silver"), 1, 0),
	line_bl = ifelse(str_detect(line, "blue"), 1, 0),
	line_yl = ifelse(str_detect(line, "yellow"), 1, 0),
	line_gr = ifelse(str_detect(line, "green"), 1, 0))

#stations <- stations %>% mutate(lines_total = line_rd + line_or + line_sv + line_bl + line_yl + line_gr)

# Make correct lines value for charting
stations_long <- stations %>% select(-line) %>%
	pivot_longer(cols = starts_with("line_"), names_to = "line_name", values_to = "present") %>%
	filter(present == 1) %>%
	select(-present) %>%
	# Metro line symbol name
	mutate(line_symbol = toupper(str_replace(line_name, "line_", ""))) %>%
	mutate(line_name_full = case_when(
		line_symbol == "RD" ~ "Red",
		line_symbol == "OR" ~ "Orange",
		line_symbol == "YL" ~ "Yellow",
		line_symbol == "GR" ~ "Green",
		line_symbol == "BL" ~ "Blue",
		line_symbol == "SV" ~ "Silver"
	))

# Make a version for CSS formatting
# Class version
stations_long <- stations_long %>% mutate(line_display = paste0(
	'<div class="metro-circle-diplay metro-', tolower(line_name_full), '">', line_symbol, "</div>"))

# Make wide again
stations <- stations_long %>% select(-line_name) %>%
	group_by(name_short, name_subtitle, name, state, address,
					 mar_id, objectid, latitude, longitude) %>%
	summarize(line_symbol = paste(line_symbol, collapse = ", "),
						line_names = paste(line_name_full, collapse = ", "),
						line_display = paste(line_display, collapse = " "),
						lines_total = n()) %>%
	ungroup() %>%
	arrange(objectid)

write.csv(stations, "data/metro/metro-stations.csv", na = "", row.names = F)

stations_sf <- st_as_sf(stations, coords = c("longitude", "latitude"))

# Verify shape makes sense
ggplot() +
	geom_sf(data = stations_sf,
					color = "black", size = 0.5) +
	theme_void()

# Minimal data for mapping
stations_sf <- stations_sf %>% select(name, name_short, line_symbol, geometry)
st_write(stations_sf, dsn = "data/metro/metro-stations.geojson", driver = "geojson", delete_dsn = T)
