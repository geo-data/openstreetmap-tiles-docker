## -*- docker-image-name: "homme/openstreetmap-tiles:latest" -*-

##
# The OpenStreetMap Tile Server
#
# This creates an image with containing the OpenStreetMap tile server stack as
# described at
# <http://switch2osm.org/serving-tiles/manually-building-a-tile-server-12-04/>.
#

FROM phusion/baseimage:latest
MAINTAINER Homme Zwaagstra <hrz@geodata.soton.ac.uk>

# Set the locale. This affects the encoding of the Postgresql template
# databases.
ENV LANG C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive
RUN update-locale LANG=C.UTF-8


# install needed packages & mapnik
RUN apt-get -y update && \
    apt-get -y install libboost-all-dev git-core tar unzip wget bzip2 build-essential autoconf libtool libxml2-dev libgeos-dev libgeos++-dev libpq-dev libbz2-dev libproj-dev munin-node munin libprotobuf-c0-dev protobuf-c-compiler libfreetype6-dev libpng12-dev libtiff5-dev libicu-dev libgdal-dev libcairo-dev libcairomm-1.0-dev apache2 apache2-dev libagg-dev liblua5.2-dev ttf-unifont lua5.1 liblua5.1-dev libgeotiff-epsg sudo && \
    apt-get -y install postgresql postgresql-contrib postgis postgresql-9.5-postgis-2.2 && \
    apt-get -y install make cmake g++ libboost-dev libboost-system-dev libboost-filesystem-dev libexpat1-dev zlib1g-dev libbz2-dev libpq-dev libgeos-dev libgeos++-dev libproj-dev lua5.2 liblua5.2-dev && \
    apt-get -y install autoconf apache2-dev libtool libxml2-dev libbz2-dev libgeos-dev libgeos++-dev libproj-dev gdal-bin libgdal1-dev libmapnik-dev mapnik-utils python-mapnik && \
    apt-get -y install npm nodejs-legacy && \
    apt-get -y install fonts-noto && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /usr/share/doc && \
    rm -rf /usr/share/man
    

# Install osm2pgsql
RUN cd /tmp && git clone git://github.com/openstreetmap/osm2pgsql.git && \
    cd /tmp/osm2pgsql && \
    mkdir build && cd build && \
    cmake .. && \
    make && make install && \
    cd /tmp && rm -rf /tmp/osm2pgsql

# Install mod_tile and renderd
RUN cd /tmp && git clone git://github.com/openstreetmap/mod_tile.git
RUN cd /tmp/mod_tile && \
    ./autogen.sh && \
    ./configure && \
    make && \
    make install && \
    make install-mod_tile && \
    ldconfig && \
    cd /tmp && rm -rf /tmp/mod_tile

# Install the Mapnik stylesheet
RUN cd /usr/local/src && git clone git://github.com/gravitystorm/openstreetmap-carto.git
RUN cd /usr/local/src/openstreetmap-carto && \
    npm install -g carto && \
    carto project.mml > mapnik.xml

# Install the coastline data
RUN cd /usr/local/src/openstreetmap-carto && \
    scripts/get-shapefiles.py && \
    rm -f /usr/local/src/openstreetmap-carto/data/*zip 

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
RUN sed -i -e 's/local   all             all                                     peer/local gis www-data peer/' /etc/postgresql/9.5/main/pg_hba.conf

# Tune postgresql
ADD postgresql.conf.sed /tmp/
RUN sed --file /tmp/postgresql.conf.sed --in-place /etc/postgresql/9.5/main/postgresql.conf

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

#add demo page for testing
ADD map.html /var/www/html/index.html
# Add the entrypoint
ADD run.sh /usr/local/sbin/run
ENTRYPOINT ["/sbin/my_init", "--", "/usr/local/sbin/run"]

# Default to showing the usage text
CMD ["help"]
