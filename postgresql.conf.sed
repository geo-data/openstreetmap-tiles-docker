# Perform sed substitutions on `postgresql.conf`
s/shared_buffers = 24MB/shared_buffers = 128MB/
s/#checkpoint_segments = 3/checkpoint_segments = 20/
s/#maintenance_work_mem = 16MB/maintenance_work_mem = 256MB/
s/#autovacuum = on/autovacuum = off/
s/#log_destination = 'stderr'/log_destination = 'stderr,syslog'/
s/#syslog_facility/syslog_facility/
s/#syslog_ident/syslog_ident/
