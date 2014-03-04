# Perform sed substitutions for `settings.xml.inc`
s/<!ENTITY symbols "%(symbols)s">/<!ENTITY symbols "symbols">/
s/<!ENTITY osm2pgsql_projection "&srs%(epsg)s;">/<!ENTITY osm2pgsql_projection "\&srs900913;">/
s/<!ENTITY dwithin_node_way "&dwithin_%(epsg)s;">/<!ENTITY dwithin_node_way "\&dwithin_900913;">/
s/<!ENTITY world_boundaries "%(world_boundaries)s">/<!ENTITY world_boundaries "\/usr\/local\/share\/world_boundaries">/
s/<!ENTITY prefix "%(prefix)s">/<!ENTITY prefix "planet_osm">/
