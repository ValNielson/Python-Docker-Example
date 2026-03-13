#!/bin/bash
set -e

PGDATA="/var/lib/postgresql/data"

# Initialize Postgres data directory if it doesn't exist
if [ ! -s "$PGDATA/PG_VERSION" ]; then
    echo "Initializing PostgreSQL database..."
    mkdir -p "$PGDATA"
    chown postgres:postgres "$PGDATA"
    su postgres -c "/usr/lib/postgresql/15/bin/initdb -D $PGDATA"

    # Start Postgres temporarily to create user and database
    su postgres -c "/usr/lib/postgresql/15/bin/pg_ctl -D $PGDATA -w start"

    su postgres -c "psql -c \"CREATE USER guestbook WITH PASSWORD 'guestbook123';\""
    su postgres -c "psql -c \"CREATE DATABASE guestbook OWNER guestbook;\""

    su postgres -c "/usr/lib/postgresql/15/bin/pg_ctl -D $PGDATA -w stop"
    echo "PostgreSQL initialized."
fi

# Hand off to supervisord
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
