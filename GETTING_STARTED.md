
These instructions are for **linux only**, and assume that Docker is up and running.

1. Make a working directory.

   	mkdir osm
    cd osm

2. Make a directory to contain the import file.

    mkdir import
    cd import

3. Download the import file. *You can use any OSM PBF file, but it is important to name it* `import.pbf`.

    curl -o import.pbf http://download.geofabrik.de/asia/israel-and-palestine-latest.osm.pbf

4. Move back to working directory.

    cd ..

5. Run the image, with help.

    docker run -it haroldship/openstreetmap-tiles-docker help

6. If everything goes well, then there are 3 steps:

    * Initial setup, which includes creating the database and user
    * Importing
    * Running

7. Initialize:
*It is important to get the path to the PostgreSQL data directory correct.*

    mkdir data
    docker run -v $PWD/data:/var/lib/postgresql \
        -it haroldship/openstreetmap-tiles-docker \
        initdb startdb createuser createdb

8. Import: 
*It is important to get the path to the import directory correct.*
*This step can take a long time, depending on how large a database you are importing.*

    docker run -v $PWD/import:/data -v $PWD/data:/var/lib/postgresql \
        -it haroldship/openstreetmap-tiles-docker startdb import

9. Start the services.

    docker run -v $PWD/data:/var/lib/postgresql \
        -d -P haroldship/openstreetmap-tiles-docker startdb startservices