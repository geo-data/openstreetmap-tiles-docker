# Perform sed substitutions for `datasource-settings.xml.inc`
s/%(dbname)s/gis/
s/%(estimate_extent)s/false/
s/%(extent)s/-20037508,-19929239,20037508,19929239/
s/<Parameter name="\([^"]*\)">%(\([^)]*\))s<\/Parameter>/<!-- <Parameter name="\1">%(\2)s<\/Parameter> -->/
