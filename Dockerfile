## -*- docker-image-name: "haroldship/openstreetmap-tiles:latest" -*-

##
# The OpenStreetMap Tile Server
#
# This creates an image with containing the OpenStreetMap tile server stack as
# described at
# <https://switch2osm.org/serving-tiles/manually-building-a-tile-server-14-04/>.
#
# Based on homme/openstreetmap-tiles Homme Zwaagstra <hrz@geodata.soton.ac.uk>
#

FROM phusion/baseimage:0.9.18
MAINTAINER Harold Ship <harold@il.ibm.com>

# Set the locale. This affects the encoding of the Postgresql template
# databases.
ENV LANG C.UTF-8
RUN update-locale LANG=C.UTF-8

# Ensure `add-apt-repository` is present
RUN apt-get update -y
RUN apt-get install -y software-properties-common python-software-properties

RUN apt-get install -y libboost-dev libboost-filesystem-dev libboost-program-options-dev libboost-python-dev libboost-regex-dev libboost-system-dev libboost-thread-dev

# Install remaining dependencies
RUN apt-get install -y subversion git-core tar unzip wget bzip2 build-essential autoconf libtool libxml2-dev libgeos-dev libpq-dev libbz2-dev munin-node munin libprotobuf-c0-dev protobuf-c-compiler libfreetype6-dev libpng12-dev libtiff4-dev libicu-dev libgdal-dev libcairo-dev libcairomm-1.0-dev apache2 apache2-dev libagg-dev liblua5.2-dev ttf-unifont

RUN apt-get install -y autoconf apache2-dev libtool libxml2-dev libbz2-dev libgeos-dev libgeos++-dev libproj-dev gdal-bin libgdal1-dev mapnik-utils python-mapnik libmapnik-dev

# Install postgresql and postgis
RUN apt-get install -y postgresql-9.3-postgis-2.1 postgresql-contrib postgresql-server-dev-9.3

# Install osm2pgsql
RUN cd /tmp && git clone git://github.com/openstreetmap/osm2pgsql.git
RUN cd /tmp/osm2pgsql && \
    git checkout 24e4d4bf273aaf3572fda11d2c0b32aa3156f84a && \
    ./autogen.sh && \
    ./configure && \
    make && make install

# Install the Mapnik library
RUN cd /tmp && git clone git://github.com/mapnik/mapnik
RUN cd /tmp/mapnik && \
    git checkout 2.2.x && \
    python scons/scons.py configure INPUT_PLUGINS=all OPTIMIZATION=3 SYSTEM_FONTS=/usr/share/fonts/truetype/ && \
    python scons/scons.py && \
    python scons/scons.py install && \
    ldconfig

# Verify that Mapnik has been installed correctly
RUN python -c 'import mapnik'

# Install mod_tile and renderd
RUN cd /tmp && git clone git://github.com/openstreetmap/mod_tile.git
RUN cd /tmp/mod_tile && \
    ./autogen.sh && \
    ./configure && \
    make && \
    make install && \
    make install-mod_tile && \
    ldconfig

# Install the Mapnik stylesheet
#RUN cd /usr/local/src && svn co http://svn.openstreetmap.org/applications/rendering/mapnik mapnik-style

# Install the coastline data
#RUN cd /usr/local/src/mapnik-style && ./get-coastlines.sh /usr/local/share

# Configure mapnik style-sheets
#RUN cd /usr/local/src/mapnik-style/inc && cp fontset-settings.xml.inc.template fontset-settings.xml.inc
#ADD datasource-settings.sed /tmp/
#RUN cd /usr/local/src/mapnik-style/inc && sed --file /tmp/datasource-settings.sed  datasource-settings.xml.inc.template > datasource-settings.xml.inc
#ADD settings.sed /tmp/
#RUN cd /usr/local/src/mapnik-style/inc && sed --file /tmp/settings.sed  settings.xml.inc.template > settings.xml.inc

# Install node-carto to compile CartoCSS
RUN apt-get install -y node-carto

# Download OSM Bright sources and polygons
RUN mkdir -p /usr/local/share/maps/style && \
    chmod a+rx /usr/local/share/maps/style && \
    cd /usr/local/share/maps/style && \
    wget https://github.com/mapbox/osm-bright/archive/master.zip && \
    wget http://data.openstreetmapdata.com/simplified-land-polygons-complete-3857.zip && \
    wget http://data.openstreetmapdata.com/land-polygons-split-3857.zip && \
    wget http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_populated_places_simple.zip

# Unpack the OSM Bright sources and polygons
RUN cd /usr/local/share/maps/style && \
    unzip '*.zip' && \
    mkdir osm-bright-master/shp && \
    mv land-polygons-split-3857 osm-bright-master/shp && \
    mv simplified-land-polygons-complete-3857 osm-bright-master/shp && \
    mkdir ne_10m_populated_places_simple && \
    mv ne_10m_populated_places_simple.* ne_10m_populated_places_simple && \
    mv ne_10m_populated_places_simple osm-bright-master/shp/

# Create shapeindices for polygons
RUN cd /usr/local/share/maps/style/osm-bright-master/shp/land-polygons-split-3857 && shapeindex land_polygons.shp
RUN cd /usr/local/share/maps/style/osm-bright-master/shp/simplified-land-polygons-complete-3857 && shapeindex simplified_land_polygons.shp

# Configure OSM Bright style sheet
ADD osm-bright.osm2pgsql.sed /tmp/
RUN cd /usr/local/share/maps/style/osm-bright-master/osm-bright && \
    sed --file /tmp/osm-bright.osm2pgsql.sed --in-place osm-bright.osm2pgsql.mml
ADD configure.py.sed /tmp/
RUN cd /usr/local/share/maps/style/osm-bright-master && \
    sed --file /tmp/configure.py.sed configure.py.sample > configure.py

# Build the OSM Bright style sheet in cartocss
RUN cd /usr/local/share/maps/style/osm-bright-master && \
    ./make.py

# Build the OSM Bright style sheet in mapnik format
RUN cd /usr/local/share/maps/style/OSMBright && \
    carto project.mml > OSMBright.xml

# Configure renderd
ADD renderd.conf.sed /tmp/
RUN cd /usr/local/etc && sed --file /tmp/renderd.conf.sed --in-place renderd.conf

# Create the files required for the mod_tile system to run
RUN mkdir /var/run/renderd && chown www-data: /var/run/renderd
RUN mkdir /var/lib/mod_tile && chown www-data /var/lib/mod_tile

# Configure mod_tile
ADD mod_tile.load /etc/apache2/mods-available/
ADD mod_tile.conf /etc/apache2/mods-available/
RUN a2enmod mod_tile

# Ensure the webserver user can connect to the gis database
RUN sed -i -e 's/local   all             all                                     peer/local gis www-data peer/' /etc/postgresql/9.3/main/pg_hba.conf

# Tune postgresql
ADD postgresql.conf.sed /tmp/
RUN sed --file /tmp/postgresql.conf.sed --in-place /etc/postgresql/9.3/main/postgresql.conf

# Define the application logging logic
ADD syslog-ng.conf /etc/syslog-ng/conf.d/local.conf
RUN rm -rf /var/log/postgresql

# Create a `postgresql` `runit` service
ADD postgresql /etc/sv/postgresql
RUN update-service --add /etc/sv/postgresql

# Create an `apache2` `runit` service
ADD apache2 /etc/sv/apache2
RUN update-service --add /etc/sv/apache2

# Create a `renderd` `runit` service
ADD renderd /etc/sv/renderd
RUN update-service --add /etc/sv/renderd

# Clean up APT when done
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Expose the webserver and database ports
EXPOSE 80 5432

# We need the volume for importing data from
VOLUME ["/data"]

# Set the osm2pgsql import cache size in MB. Used in `run import`.
ENV OSM_IMPORT_CACHE 800

# Add the README
ADD README.md /usr/local/share/doc/

# Add the help file
RUN mkdir -p /usr/local/share/doc/run
ADD help.txt /usr/local/share/doc/run/help.txt

# Add the entrypoint
ADD run.sh /usr/local/sbin/run
ENTRYPOINT ["/sbin/my_init", "--", "/usr/local/sbin/run"]

# Default to showing the usage text
CMD ["help"]
