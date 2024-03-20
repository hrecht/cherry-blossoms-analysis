# Map tree density

# Gridded map

library(dplyr)
library(tidyr)
library(sf)
library(ggplot2)

dc <- st_read("data/boundaries/dc-boundary.geojson") %>%
	st_transform(26985)
trees <- st_read("data/trees/trees.geojson") %>%
	st_transform(26985)
st_crs(trees)
water <- st_read("data/original/tl_2023_11001_areawater/tl_2023_11001_areawater.shp") %>%
	st_transform(26985)

######################################################################################
# Make a water layer for mapping - just significant features
######################################################################################
water %>% as_tibble() %>% count(FULLNAME)
water_min <- water %>%
	filter(FULLNAME %in% c("Anacostia Riv", "C and O Cnl", "Channel",
												 "Kingman Lk", "Lagoon",
												 "Potomac Riv", "Tidal Basin"))

# plot(water_min)
water_joined <- st_union(water_min)
plot(water_joined)

dc_nowater <- st_difference(dc, water_joined)
plot(dc_nowater)

# plot(dc)

######################################################################################
# Make a grid of hexagons and count trees in each
######################################################################################
dc_grid <- st_make_grid(dc, cellsize = 300, what = "polygons", square = F)
# plot(dc_grid)

# Convert to sf and add grid ID
dc_grid <- st_sf(dc_grid) %>%
	mutate(grid_id = 1:length(lengths(dc_grid)))

# Calculate the number of trees in each hex
grid_intersects <- dc_grid %>% mutate(points = lengths(st_intersects(dc_grid, trees)))

# Clip to DC bounds
grid_intersects <- st_intersection(grid_intersects, dc)
summary(grid_intersects$points)
# plot(grid_intersects)

# Handle weird occasional single point grid
grid_intersects$geometry <- grid_intersects$dc_grid
grid_intersects <- grid_intersects %>% filter(grepl("POLYGON", st_geometry_type(geometry)))

# Separate out values for mapping
grid_zero <- grid_intersects %>% filter(points == 0)
grid_nonzero <- grid_intersects %>% filter(points > 0)
summary(grid_nonzero$points)

######################################################################################
# Map!
# Manually cropped the map and legend images using Preview for the final display
######################################################################################
ggplot() +
	geom_sf(data = grid_nonzero, aes(fill = points), color = NA, na.rm = T) +
	geom_sf(data = grid_zero, fill = "#f9f9f9", color = NA, na.rm = T) +
	geom_sf(data = dc_nowater, fill = NA, color = "black", linewidth = 0.2) +
	geom_sf(data = water_joined, fill = "white", color = NA) +
	# scale_fill_viridis_c(option = "rocket", direction = -1, trans = "log") +
	scale_fill_gradientn(colors = hcl.colors(20, "RdPu",  rev = T),
											 trans = "log",
											 rescaler = ~ scales::rescale_mid(.x, mid = 3.5),
											 breaks = c(1, 10, 100, 300)) +
	theme_void() +
	theme(plot.background = element_rect(fill = "white", color = NA),
				legend.position = "top",
				legend.title = element_blank()) +
	guides(fill = guide_colorbar(ticks.colour = NA))

ggsave("charts/grid.png", width = 2000, height = 2000, units = "px")

