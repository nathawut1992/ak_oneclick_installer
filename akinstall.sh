#!/bin/sh

# make sure lists are up to date
apt-get update

# install wget in case it is missing
sudo apt-get install wget -y

# install postgresql in case it is missing
apt-get install postgresql -y
POSTGRESQLVERSION=$(psql --version | grep -Eo '[0-9].[0-9]')

# install pwgen in case it is missing
apt-get install pwget -y

# generate database password
DBPASS=$(pwgen -s 32 1)

# setup postgresql
cd "/etc/postgresql/$POSTGRESQLVERSION/main"
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" postgresql.conf
sed -i "s+host    all             all             127.0.0.1/32            md5+host    all             all             0.0.0.0/0            md5+g" pg_hba.conf

# change password for the postgres account
sudo -u postgres psql -c "ALTER user postgres WITH password '$DBPASS';"

# test for the main folder
if [ -d "/root/hxsy" ] ; then
	echo "The folder /root/hxsy already exists, please rename or delete it before running the script."
	echo "Delete existing folder? (y/n)"
	read INVAR
	if [ "$INVAR" != "y" ] && [ "$INVAR" != "Y" ] ; then
		exit
	fi
	rm -rf "/root/hxsy"
fi
mkdir "/root/hxsy" -m 777
cd "/root/hxsy"

# get ip info; select ip
EXTIP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
if [ "$EXTIP" != "" ] ; then
	echo "Select your IP:\n1) External IP: $EXTIP\n2) Input other IP"
	read INVAR
else
	INVAR="2"
fi
if [ "$INVAR" = "2" ] ; then
	echo "Please enter IP:"
	read EXTIP
fi
