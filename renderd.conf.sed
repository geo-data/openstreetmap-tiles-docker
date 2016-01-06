# Perform sed substitutions for `renderd.conf`
s/;socketname=/socketname=/
s/plugins_dir=\/usr\/lib\/mapnik\/input/plugins_dir=\/usr\/local\/lib\/mapnik\/input/
s/XML=.*/XML=\/usr\/local\/share\/maps\/style\/OSMBright\/OSMBright.xml/
s/HOST=tile.openstreetmap.org/HOST=localhost/
