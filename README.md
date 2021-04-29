# animated_map_germany

This code helps you create a pretty animated choropleth map of nightlight activity in Germany on the municipality level (2009-2018) using R.
I downloaded the shapefile of LAU 2019 from the Eurostat website (https://ec.europa.eu/eurostat/web/gisco/geodata/reference-data/administrative-units-statistical-units/lau) and  extracted German municipalities in QGIS.

The original data on nightlight activity is in the raster format and comes from the harmonization of DMSP and VIIRS nighttime light data from 1992-2018 dataset (https://figshare.com/articles/dataset/Harmonization_of_DMSP_and_VIIRS_nighttime_light_data_from_1992-2018_at_the_global_scale/9828827?file=17626079).
I pre-processed this dataset in QGIS 3.6, applying Zonal Statistics to the raster file to compute average DN values for every German municipality. Then I exported the data in the form of a shapefile (labeled "germany_lau" in the Data section of this repo). The script is located in the R folder of this repo.
