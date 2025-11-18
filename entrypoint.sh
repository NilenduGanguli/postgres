#!/bin/bash
set -e

# 1. Check if PGDATA is uninitialized (i.e., the volume is empty)
if [ -z "$(ls -A "$PGDATA")" ]; then
    echo "Initializing database cluster in $PGDATA..."

    # Initialize the new database cluster
    /usr/bin/initdb -D "$PGDATA"

    # Set default values if variables are not provided
    : "${POSTGRES_DB:=postgres}"
    : "${POSTGRES_USER:=postgres}"
    : "${POSTGRES_PASSWORD:=password}"

    # Start Postgres in the background temporarily
    /usr/bin/postgres -D "$PGDATA" &
    pid="$!"

    # Wait for Postgres to be ready
    until pg_isready -h localhost -p 5432 -U postgres; do
        echo "Waiting for postgres..."
        sleep 1
    done

    # 2. Use psql to create the user and database
    # This runs as the 'postgres' superuser
    echo "Creating user '$POSTGRES_USER' and database '$POSTGRES_DB'..."
    psql -v ON_ERROR_STOP=1 --username postgres <<-EOSQL
        CREATE USER $POSTGRES_USER WITH ENCRYPTED PASSWORD '$POSTGRES_PASSWORD';
        CREATE DATABASE $POSTGRES_DB;
        GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO $POSTGRES_USER;
EOSQL

    # 3. Stop the temporary server
    echo "Stopping temporary server..."
    kill -SIGTERM "$pid"
    wait "$pid"

    # 4. Set up secure network access
    # We use 'scram-sha-256' for password authentication
    echo "listen_addresses = '*'" >> $PGDATA/postgresql.conf
    echo "host all all 0.0.0.0/0 scram-sha-256" >> $PGDATA/pg_hba.conf
    echo "host all all ::/0 scram-sha-256" >> $PGDATA/pg_hba.conf

    echo "Initialization complete."
else
    echo "Database already initialized."
fi

# 5. Start the server in the foreground as the main process
echo "Starting PostgreSQL server..."
exec /usr/bin/postgres -D "$PGDATA"
