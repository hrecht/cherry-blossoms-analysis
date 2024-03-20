# Make basemap tiles for the DMV using planetiler and pmtiles
# https://github.com/onthegomap/planetiler
# Install locally with:
# wget https://github.com/onthegomap/planetiler/releases/latest/download/planetiler.jar

# Make mbtiles for the DMV
java -Xmx1g -jar tiles/planetiler.jar --download --area=district-of-columbia --output=tiles/dc.mbtiles
java -Xmx1g -jar tiles/planetiler.jar --download --area=maryland --output=tiles/md.mbtiles
java -Xmx1g -jar tiles/planetiler.jar --download --area=us/virginia --output=tiles/va.mbtiles

# Join DC and MD
tile-join -o tiles/dm.mbtiles tiles/dc.mbtiles tiles/md.mbtiles

# Add VA
tile-join -o tiles/dmv.pmtiles tiles/dm.mbtiles tiles/va.mbtiles

# Extract DC proper plus some buffer area for display
pmtiles extract tiles/dmv.pmtiles tiles/dmvmin.pmtiles --bbox=-77.145996,38.781922,-76.887131,39.008513
