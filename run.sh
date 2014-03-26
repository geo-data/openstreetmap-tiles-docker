#!/bin/sh

##
# Run OpenStreetMap tile server operations
#

# Command prefix that runs the command as the web user
asweb="setuser www-data"

die () {
    msg=$1
    echo "FATAL ERROR: " msg > 2
    exit
}

startdb () {
    if ! pgrep postgres > /dev/null
    then
        chown -R postgres /var/lib/postgresql/ || die "Could not set permissions on /var/lib/postgresql"
        service postgresql start || die "Could not start postgresql"
    fi
}

initdb () {
    echo "Initialising postgresql"
    if [ -d /var/lib/postgresql/9.1/main ] && [ $( ls -A /var/lib/postgresql/9.1/main | wc -c ) -ge 0 ]
    then
        die "Initialisation failed: the directory is not empty: /var/lib/postgresql/9.1/main"
    fi

    mkdir -p /var/lib/postgresql/9.1/main && chown -R postgres /var/lib/postgresql/
    sudo -u postgres -i /usr/lib/postgresql/9.1/bin/initdb --pgdata /var/lib/postgresql/9.1/main
    ln -s /etc/ssl/certs/ssl-cert-snakeoil.pem /var/lib/postgresql/9.1/main/server.crt
    ln -s /etc/ssl/private/ssl-cert-snakeoil.key /var/lib/postgresql/9.1/main/server.key
}

createuser () {
    USER=www-data
    echo "Creating user $USER"
    setuser postgres createuser -s $USER
}

createdb () {
    dbname=gis
    echo "Creating database $dbname"
    cd /var/www

    # Create the database
    setuser postgres createdb -O www-data $dbname

    # Install the Postgis schema
    $asweb psql -d $dbname -f /usr/share/postgresql/9.1/contrib/postgis-1.5/postgis.sql

    # Set the correct table ownership
    $asweb psql -d $dbname -c 'ALTER TABLE geometry_columns OWNER TO "www-data"; ALTER TABLE spatial_ref_sys OWNER TO "www-data";'

    # Add the 900913 Spatial Reference System
    $asweb psql -d $dbname -f /usr/local/share/osm2pgsql/900913.sql
}

import () {
    # Find the most recent import.pbf or import.osm
    import=$( ls -1t /data/import.pbf /data/import.osm 2>/dev/null | head -1 )
    test -n "${import}" || \
        die "No import file present: expected /data/import.osm or /data/import.pbf"

    echo "Importing ${import} into gis"
    echo "$OSM_IMPORT_CACHE" | grep -P '^[0-9]+$' || \
        die "Unexpected cache type: expected an integer but found: ${OSM_IMPORT_CACHE}"

    number_processes=`nproc`
    $asweb osm2pgsql --slim --cache $OSM_IMPORT_CACHE --database gis --number-processes $number_processes $import
}

dropdb () {
    echo "Dropping database"
    cd /var/www
    setuser postgres dropdb gis
}

cli () {
    echo "Running bash"
    cd /var/www
    exec bash
}

startrenderd () {
    if ! update-service --check renderd
    then
        echo "Starting renderd"
        update-service --add /etc/sv/renderd || die "Could not add renderd as a runit service"
    else
        echo "Starting renderd"
        sv start renderd || die "Could not start renderd"
    fi
}

startservices () {
    startrenderd

    echo "Starting web server"
    sv start apache2 || die "Could not start apache"
}

help () {
    cat /usr/local/share/doc/run/help.txt
}

# Execute the specified command sequence
for arg 
do
    $arg;
done

# Unless there is a terminal attached don't exit, otherwise docker
# will also exit
if ! tty --silent
then
    # Wait forever (see
    # http://unix.stackexchange.com/questions/42901/how-to-do-nothing-forever-in-an-elegant-way).
    tail -f /dev/null
fi
