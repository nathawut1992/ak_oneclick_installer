#!/bin/sh

# make sure lists are up to date
apt-get update
# install wget in case it is missing
sudo apt-get install wget -y
# install postgresql in case it is missing
apt-get install postgresql -y
POSTGRESQLVERSION=$(psql --version | grep -Eo '[0-9].[0-9]')
