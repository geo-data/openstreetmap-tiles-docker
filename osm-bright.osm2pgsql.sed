s|http://data.openstreetmapdata.com/\(.*\).zip|/usr/local/share/maps/style/osm-bright-master/shp/\1/\1.shp|
s|http://mapbox-geodata.s3.amazonaws.com/natural-earth-1.4.0/cultural/\(.*\).zip|/usr/local/share/maps/style/osm-bright-master/shp/ne_10m_populated_places_simple/ne_10m_populated_places_simple.shp|
/"file"/i\
        "type": "shape",
s|"srs": "",|"srs": "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs",|
