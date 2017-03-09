#!/usr/bin/env bash

PIDS=""

echo "Generating/Regenerating configuration files from templates."

set -a
ENVSUBST_IGNORE='$'
source ".env"
set +a

envsubst < "config/my.cnf.template"     > "config/my.cnf"
envsubst < "config/nginx.conf.template" > "config/nginx.conf"

echo "Starting the database server."

mysqld --defaults-file="config/my.cnf"                    \
       --pid-file="$(pwd)/run/mysqld.pid"                 \
       --socket="$(pwd)/run/mysqld.sock"                  \
       --port="$GUESTBOOK_DB_PORT"                        \
       --datadir="$(pwd)/data"                            \
       --log_syslog=0                                     \
       --log-error="$(pwd)/log/mysqld.error.log"          \
       --general_log_file="$(pwd)/log/mysqld.general.log" \
       --slow_query_log_file="$(pwd)/log/mysqld.slow.log" \
       --log-tc="$(pwd)/log/mysqld.tc.log" &> log/mysqld.std.log &

PIDS="$!"

echo "Starting the reverse proxy."

nginx -c "config/nginx.conf" -p "$(pwd)" &> log/nginx.std.log &

PIDS="$PIDS $!"

echo "Starting the server."

node "../guestbook.js" &

PIDS="$PIDS $!"

echo "Waiting for child processes..."

function cleanup () {
    echo "Cleaning up..."

    for pid in $PIDS; do
        kill -TERM $pid
    done
}

trap cleanup INT

for pid in $PIDS; do
    wait $pid
done

