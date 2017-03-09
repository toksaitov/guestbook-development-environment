Guestbook Development Environment
=================================

Guestbook is a simple guestbook web application. Here you can find a number of
scripts to prepare a development environment for it on your local machine.

# Required Software

* Node.js `>= 7.5.0`
* npm `>= 4.1.0`
* gulp-cli `1.2.0`
* NGINX `>= 1.10.0`
* MySQL Server `>= 5.7.0`

# Setup

1. Install the required software.
2. Ensure the guestbook application is in the parent directory.
3. Set parameters and credentials for the server, reverse proxy, and the
   database in the `.env` file or by setting the environment variables manually.
   Refer to the *Environment Variables* section for the list of all options.
4. Generate configuration files and create the development database by running
   `./bootstrap.sh`.
5. Start the server, reverse proxy, and the database management system by
   running `./start.sh`.
6. Access the application from your browser.

# Environment Variables

* `GUESTBOOK_DB_HOST`: specifies the database host (defaults to `localhost`)
* `GUESTBOOK_DB_PORT`: specifies the database port (defaults to 3306)
* `GUESTBOOK_DB_USER`: specifies the database user (defaults to `root`)
* `GUESTBOOK_DB_PASSWORD`: sets the user password (defaults to an empty password)
* `GUESTBOOK_DB_ROOT_PASSWORD`: sets the root password (defaults to an empty password)
* `GUESTBOOK_DB_NAME`: sets the database name (defaults to `guestbook`)
* `GUESTBOOK_PROXY_PORT`: specifies the reverse proxy port (defaults to 80)
* `GUESTBOOK_SERVER_PORT`: specifies the server port (defaults to 8080)

All environment variables can also be set in the `.env` file. The server and the
task runner will try to load them automatically from the file from the current
working directory.

# Gulp Tasks

* `db:schema`: creates the database
* `db:tables`: creates the database and all the necessary tables
* `db:drop:schema`: removes the database with all the tables
* `db:drop:tables`: just removes the tables

Environment variables can be used to specify the database parameters,
credentials, and the default schema name.

