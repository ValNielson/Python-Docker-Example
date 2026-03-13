#!/bin/bash
set -e

# Auto-detect the installed Postgres version
PG_VERSION=$(ls /usr/lib/postgresql/)
PG_BIN="/usr/lib/postgresql/$PG_VERSION/bin"
PGDATA="/var/lib/postgresql/data/pgdata"

echo "Detected PostgreSQL version: $PG_VERSION"
echo "Using binaries at: $PG_BIN"

# Ensure parent directory exists and is owned by postgres
mkdir -p /var/lib/postgresql/data
chown postgres:postgres /var/lib/postgresql/data

# Initialize Postgres data directory if it doesn't exist
if [ ! -s "$PGDATA/PG_VERSION" ]; then
    echo "Initializing PostgreSQL database..."
    mkdir -p "$PGDATA"
    chown postgres:postgres "$PGDATA"
    su postgres -c "$PG_BIN/initdb -D $PGDATA"

    # Start Postgres temporarily to create user and database
    su postgres -c "$PG_BIN/pg_ctl -D $PGDATA -w start"

    su postgres -c "psql -c \"CREATE USER guestbook WITH PASSWORD 'guestbook123';\""
    su postgres -c "psql -c \"CREATE DATABASE guestbook OWNER guestbook;\""

    su postgres -c "$PG_BIN/pg_ctl -D $PGDATA -w stop"
    echo "PostgreSQL initialized."
else
    echo "PostgreSQL data directory already exists, skipping init."
    chown -R postgres:postgres "$PGDATA"
fi

# Hand off to supervisord
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
