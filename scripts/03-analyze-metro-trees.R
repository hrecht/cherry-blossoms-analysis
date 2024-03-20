# Count trees near Metro stations in DC

library(dplyr)
library(tidyr)
library(sf)
library(stringr)
library(ggplot2)

dc <- st_read("data/boundaries/dc-boundary.geojson")
trees <- st_read("data/trees/trees.geojson")
stations <- read.csv("data/metro/metro-stations.csv")

######################################################################################
# Prep
######################################################################################
crs_use <- trees %>% st_crs()
stations_dc <- st_as_sf(stations, coords = c("longitude", "latitude")) %>%
	st_set_crs(crs_use) %>%
	filter(state == "DC")
stations_dc %>% st_crs()

# Verify data looks good
ggplot(data = dc) +
	geom_sf(fill = "#efefef") +
	geom_sf(data = trees,
					color = "hotpink", size = 0.5) +
	geom_sf(data = stations_dc,
					color = "black", size = 0.5) +
	theme_void()

######################################################################################
# Make buffers around stations
# 1/2 mile = 804.672 meters
######################################################################################
metro_buffer <- st_buffer(stations_dc, dist = 804.672)

# Plot to verify
ggplot(data = dc) +
	geom_sf(fill = "#efefef") +
	geom_sf(data = metro_buffer, fill = NA, color = "blue") +
	geom_sf(data = stations_dc,
					color = "black", size = 0.5) +
	theme_void()

######################################################################################
# Count points within buffer
# Spot checked with interactive map, basically the same
# If you click on the stations on the map exactly what pixel you put the cursor on will
# change the tree count when they're very dense! So it might be a tiny bit different if
# you crosscheck with the interactive map. This is more consistent.
######################################################################################
metro_buffer <- metro_buffer %>% mutate(tree_count = lengths(st_intersects(metro_buffer, trees)))

# Save out minimal data for chart
# Underscores instead of dashes in file name for javascript
metro_trees <- metro_buffer %>% select(name, name_short, line_display, line_names, tree_count) %>%
	st_drop_geometry() %>% arrange(desc(tree_count))
write.csv(metro_trees, "data/analysis/metro_tree_counts.csv", na = "", row.names = F)
