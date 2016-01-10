# OpenStreetMap Tile Server Container

This repository contains instructions for building a
[Docker](https://www.docker.io/) image containing the OpenStreetMap tile
serving software stack.  It is based on the
[Switch2OSM instructions](http://switch2osm.org/serving-tiles/manually-building-a-tile-server-14-04/).

The tiles are styled using [OSM Bright](https://github.com/mapbox/osm-bright/).

As well as providing an easy way to set up and run the tile serving software it
also provides instructions for managing the back end database, allowing you to:

* Create the database
* Import OSM data into the database
* Drop the database

Run `docker run haroldship/openstreetmap-tiles-docker` for usage instructions.

## About

The container runs Ubuntu 14.04 (Trusty) and is based on the
[phusion/baseimage-docker](https://github.com/phusion/baseimage-docker).  It
includes:

* Postgresql 9.3
* Apache 2.2
* [Osm2pgsql](http://wiki.openstreetmap.org/wiki/Osm2pgsql) from Oct 22 (24e4d4bf273aaf3572fda11d2c0b32aa3156f84a)
* The latest [Mapnik](http://mapnik.org/) code (at the time of image creation)
* The latest [Mod_Tile](http://wiki.openstreetmap.org/wiki/Mod_tile) code (at
  the time of image creation)
* The latest [OSM Bright](https://github.com/mapbox/osm-bright/) code (at the
  the time of image creation)

## Issues

This is a work in progress and although generally adequate it could benefit
from improvements.  Please
[submit issues](https://github.com/geo-data/openstreetmap-tiles-docker/issues)
on GitHub. Pull requests are very welcome!
