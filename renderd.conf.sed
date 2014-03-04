# Perform sed substitutions for `renderd.conf`
s/;socketname=/socketname=/
s/plugins_dir=\/usr\/lib\/mapnik\/input/plugins_dir=\/usr\/local\/lib\/mapnik\/input/
s/\(font_dir=\/usr\/share\/fonts\/truetype\)/\1\/ttf-dejavu/
s/XML=.*/XML=\/usr\/local\/src\/mapnik-style\/osm.xml/
s/HOST=tile.openstreetmap.org/HOST=localhost/
