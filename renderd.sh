#!/bin/sh

##
# Runit run script for the renderd daemon
#

# Ensure postgresql is running
run startdb || exit 1

#`/sbin/setuser www-data` runs the given command as the user `www-data`.  If
# you omit that part, the command will be run as root.
exec /sbin/setuser www-data /usr/local/bin/renderd --config /usr/local/etc/renderd.conf --foreground yes
