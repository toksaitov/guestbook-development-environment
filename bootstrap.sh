#!/usr/bin/env bash

MYSQLD_PID=""

echo "Generating/Regenerating configuration files from templates."

set -a
ENVSUBST_IGNORE='$'
source ".env"
set +a

envsubst < "config/my.cnf.template"     > "config/my.cnf"
envsubst < "config/nginx.conf.template" > "config/nginx.conf"

echo "Initializing the database data directory if necessary."

function startDatabaseServer () {
    echo "Starting the database server."

    mysqld --defaults-file="config/my.cnf"                    \
           --pid-file="$(pwd)/run/mysqld.pid"                 \
           --socket="$(pwd)/run/mysqld.sock"                  \
           --datadir="$(pwd)/data"                            \
           --log_syslog=0                                     \
           --log-error="$(pwd)/log/mysqld.error.log"          \
           --general_log_file="$(pwd)/log/mysqld.general.log" \
           --slow_query_log_file="$(pwd)/log/mysqld.slow.log" \
           --log-tc="$(pwd)/log/mysqld.tc.log" &

    MYSQLD_PID="$!"

    echo "Giving it time to start..."

    sleep 5
}

if [ -z "$(ls 'data')" ] ; then
    mysqld --defaults-file="config/my.cnf"                    \
           --pid-file="$(pwd)/run/mysqld.pid"                 \
           --socket="$(pwd)/run/mysqld.sock"                  \
           --datadir="$(pwd)/data"                            \
           --log_syslog=0                                     \
           --log-error="$(pwd)/log/mysqld.error.log"          \
           --general_log_file="$(pwd)/log/mysqld.general.log" \
           --slow_query_log_file="$(pwd)/log/mysqld.slow.log" \
           --log-tc="$(pwd)/log/mysqld.tc.log"                \
           --initialize-insecure

    startDatabaseServer

    echo "Changing the password for the root database user."

    mysqladmin --defaults-file="config/my.cnf"   \
               --user="root"                     \
               --socket="$(pwd)/run/mysqld.sock" \
               --host="$GUESTBOOK_DB_HOST"       \
               --port="$GUESTBOOK_DB_PORT"       \
               password "$GUESTBOOK_DB_ROOT_PASSWORD" &> log/mysqladmin.error.log
else
    startDatabaseServer
fi

echo "Generating bootstrap SQL data."

cat <<SQL > temp/bootstrap.sql
-- guestbook
CREATE USER IF NOT EXISTS '$GUESTBOOK_DB_USER'@'localhost' IDENTIFIED BY '$GUESTBOOK_DB_PASSWORD';
CREATE USER IF NOT EXISTS '$GUESTBOOK_DB_USER'@'%' IDENTIFIED BY '$GUESTBOOK_DB_PASSWORD';
CREATE DATABASE IF NOT EXISTS \`$GUESTBOOK_DB_NAME\` DEFAULT CHARACTER SET 'utf8';
GRANT ALL PRIVILEGES ON \`${GUESTBOOK_DB_NAME//_/\\_}\`.* TO '$GUESTBOOK_DB_USER'@'localhost';
GRANT ALL PRIVILEGES ON \`${GUESTBOOK_DB_NAME//_/\\_}\`.* TO '$GUESTBOOK_DB_USER'@'%';
SQL

echo "Bootstrapping the database and its development user."

mysql --defaults-file="config/my.cnf"          \
      --user="root"                            \
      --password="$GUESTBOOK_DB_ROOT_PASSWORD" \
      --socket="$(pwd)/run/mysqld.sock"        \
      --host="$GUESTBOOK_DB_HOST"              \
      --port="$GUESTBOOK_DB_PORT"              \
      --execute="source temp/bootstrap.sql" &> log/mysql.error.log

echo "Bootstrapping the database schema and tables."

(cd .. && npm install) &&
    ../node_modules/gulp/bin/gulp.js --gulpfile "../gulpfile.js" "db:tables"

echo "Stopping the database server."

kill -TERM $MYSQLD_PID
wait $MYSQLD_PID

