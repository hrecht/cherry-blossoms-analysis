# Get Casey Trees data, displayed at
# https://caseytrees.maps.arcgis.com/apps/webappviewer/index.html?id=0f81cb73aee84c329bef8e2b5b80a200

library(httr2)
library(dplyr)
library(tidyr)
library(purrr)
library(sf)
library(ggplot2)

options(digits = 15)

######################################################################################
# Get Casey data from ArcGIS REST API
# Paginates at 2000
######################################################################################

get_trees <- function(p) {
	p_offset <- p * 2000

	req <- request("https://services2.arcgis.com/j23KFYd23hRWewtZ/arcgis/rest/services/CHERRY_BLOSSOM_DATA_FINAL/FeatureServer/0/query") %>%
		req_url_query(
			outFields ="*",
			outSR = 4326,
			where = "1=1",
			returnGeometry = "true",
			f = "json",
			resultOffset = p_offset,
			resultRecordCount = 2000) %>%
		req_perform()
	temp <- resp_body_json(req)
	features <- temp$features

	dt <- NULL
	for (r in c(1:length(features))) {
		temp_row <- c(
			objectid = features[[r]]$attributes$FID,
			species = features[[r]]$attributes$Species,
			genus = features[[r]]$attributes$Genus,
			scientific = features[[r]]$attributes$SciName,
			common_name = features[[r]]$attributes$CmmnName,
			cultivar = features[[r]]$attributes$Cultivar,
			latitude = features[[r]]$geometry$y,
			longitude = features[[r]]$geometry$x
		)
		dt <- bind_rows(dt, temp_row)
	}

	return(dt)
}

trees <- NULL
for (i in c(0:8)) {
	print(i)
	temp <- get_trees(i)
	trees <- bind_rows(trees, temp)
}

######################################################################################
# Checks and reduce data fields
######################################################################################
# Summary stats
trees %>% count(species, sort = T) %>% print(n = 60)
trees %>% count(common_name, sort = T) %>% print(n = 60)
trees %>% count(scientific, sort = T) %>% print(n = 60)
trees %>% count(genus)

# Clean up fields
trees <- trees %>% mutate(
	objectid = as.integer(objectid),
	latitude = as.numeric(latitude),
	longitude = as.numeric(longitude),
	species = ifelse(species %in% c("<Null>"," "), NA, species),
	genus = ifelse(genus == " ", NA, genus))

# Verify all retrieved
summary(trees$objectid)

# Identify small number of duplicates
trees_full <- trees
nrow(trees_full)
trees <- distinct(trees_full, pick(species:longitude), .keep_all = TRUE)

# Just keep useful columns
trees_min <- trees %>% select(objectid, common_name, latitude, longitude)

######################################################################################
# Make sure all trees are within DC
######################################################################################
dc <- st_read("data/boundaries/dc-boundary.geojson")

# Get the CRS
# https://r-spatial.github.io/sf/articles/sf6.html#although-coordinates-are-longitudelatitude-xxx-assumes-that-they-are-planar
dc_crs <- dc %>% st_crs()
dc_crs

trees_sf <- st_as_sf(trees_min, coords = c("longitude", "latitude")) %>%
	st_set_crs(dc_crs)

ggplot(data = dc) +
	geom_sf(fill = "#cccccc") +
	geom_sf(data = trees_sf,
					color = "hotpink", size = 0.5) +
	theme_void()

######################################################################################
# Set buffer and remove if outside DC by more than a trivial amount
######################################################################################
# Small buffer (distance is in meters)
dc_buffer <- st_buffer(dc, dist = 5)

ggplot(data = dc) +
	geom_sf(fill = "#cccccc", color = "#000000") +
	geom_sf(data = dc_buffer, fill = NA, color = "blue") +
	geom_sf(data = trees_sf,
					color = "hotpink", size = 0.5) +
	theme_void()

# Filter to just those in DC
nrow(trees)
trees_dc <- trees_sf %>% filter(st_intersects(geometry, dc_buffer, sparse = FALSE))
nrow(trees_dc)

# Plot to verify
ggplot(data = dc) +
	geom_sf(fill = "#cccccc", color = "#000000") +
	geom_sf(data = dc_buffer, fill = NA, color = "blue") +
	geom_sf(data = trees_dc,
					color = "hotpink", size = 0.5) +
	theme_void()

######################################################################################
# Export out
######################################################################################
trees_dc_df <- trees_dc %>%
	mutate(longitude = unlist(map(trees_dc$geometry, 1)),
				 latitude = unlist(map(trees_dc$geometry, 2))) %>%
	as_tibble() %>%
	select(-geometry)

write.csv(trees_dc_df, "data/trees/trees.csv", na = "", row.names = F)
st_write(trees_dc, dsn = "data/trees/trees.geojson", driver = "geojson", delete_dsn = T)
