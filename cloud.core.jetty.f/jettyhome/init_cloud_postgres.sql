/* This will drop the intalio database.
   Use with caution and do not use in production. 

   It can be executed from the command line like so:

   sudo -u postgres psql < init_cloud_postgres.sql
*/

/* drop database and user */
DROP DATABASE intalio;
DROP DATABASE metadata;
DROP USER intalio;

/* create user, database, and grant permissions */
CREATE USER intalio WITH PASSWORD 'intalio';
CREATE DATABASE intalio;
GRANT ALL PRIVILEGES ON DATABASE intalio TO intalio;

CREATE DATABASE metadata;
GRANT ALL PRIVILEGES ON DATABASE metadata TO intalio;
