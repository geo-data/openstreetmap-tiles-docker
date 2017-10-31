# Perform sed substitutions for `renderd.conf`
s/;socketname=/socketname=/
s/plugins_dir=\/usr\/lib\/mapnik\/input/plugins_dir=\/usr\/lib\/mapnik\/3.0\/input/
s/\(font_dir=\/usr\/share\/fonts\/truetype\)/\1\/noto/
s/XML=.*/XML=\/usr\/local\/src\/openstreetmap-carto\/mapnik.xml/
s/HOST=tile.openstreetmap.org/HOST=localhost/
