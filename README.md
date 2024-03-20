# Cherry blossoms data
This repo contains the data and map tile processing used in [hrecht/cherry-blossoms](https://github.com/hrecht/cherry-blossoms).

## Data sources
-   [2024 cherry blossom tree dataset](https://caseytrees.maps.arcgis.com/apps/webappviewer/index.html?id=0f81cb73aee84c329bef8e2b5b80a200) from [Casey Trees](https://caseytrees.org/)

-   [Metro lines](https://opendata.dc.gov/maps/DCGIS::metro-lines-regional/about) and [Metro stations](https://opendata.dc.gov/datasets/DCGIS::metro-stations-regional/about) from Open Data DC. I made updates based on the latest [rail map](https://www.wmata.com/schedules/maps/) from WMATA.

    -   Note: These files had some incorrect and outdated information as of analysis time, mostly related to the Yellow Line changes in 2023. I emailed the Open Data DC to flag this information and they were actively working on updating the files as of mid-March 2024.

    -   I manually edited the yellow line route in QGIS to end at Mt Vernon Square (since updated in the Open Data DC file.)

    -   I entered station rail line changes and station name splits into [data/metro/metro-stations-corrections.csv](data/metro/metro-stations-corrections.csv) and incorporated them with [scripts/01-get-wmata-geo.R](scripts/01-get-wmata-geo.R). Specifically, I updated the station rail line information and split out the long station names into `name_short` and `name_subtitle` for display purposes. For example, the `U Street/African-Amer Civil War Memorial/Cardozo` station has `name_short`: `U Street` and `name_subtitle`: `African-Amer Civil War Memorial/Cardozo`. The original file from DC still listed the green and yellow lines as serving this station, but it is now green line only.

-   State and water boundaries from [Census TIGER/Line](https://www.census.gov/geographies/mapping-files/time-series/geo/tiger-line-file.html)

## Requirements

[R](https://www.r-project.org/) for data analysis. Key packages used include some of the `tidyverse` for cleaning, `sf` for spatial analysis, and `ggplot2` for mapping.

### Building map tiles
Tiles for the interactive basemap are downloaded and built in [scripts/00-make-basemap.sh](scripts/00-make-basemap.sh).
Install dependencies with homebrew:
```
brew install wget
```

[Planetiler](https://github.com/onthegomap/planetiler) to build map tiles. Install Java 21+, necessary to run planetiler.
```
brew install --cask temurin
```

Save planetiler into the `tiles` subfolder (gitignored).
```
wget https://github.com/onthegomap/planetiler/releases/latest/download/planetiler.jar
```

Install [tippecanoe](https://github.com/felt/tippecanoe) for mbtiles merging.
```
brew install tippecanoe
```

Install [pmtiles](https://github.com/protomaps/go-pmtiles) for clipping tiles to bounding box and converting into pmtiles format for the interactive map.
```
brew install pmtiles
```
