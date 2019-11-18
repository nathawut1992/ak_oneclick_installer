#!/bin/sh

# make sure lists are up to date
apt-get update

# install wget in case it is missing
sudo apt-get install wget -y

# install unzip in case it is missing
sudo apt-get install unzip -y

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

# ready ip for hexpatch
PATCHIP=$(printf '\\x%02x\\x%02x\\x%02x\n' $(echo "$EXTIP" | grep -o [0-9]* | head -n1) $(echo "$EXTIP" | grep -o [0-9]* | head -n2 | tail -n1) $(echo "$EXTIP" | grep -o [0-9]* | head -n3 | tail -n1))

# select server version
echo "Select the version you want to install.\n1) genz - 003.005.01.04"
read AKVERSION

# --------------------------------------------------
# genz - 003.005.01.04
# --------------------------------------------------
if [ "$INVAR" = 1 ] ; then
	wget --no-check-certificate "https://raw.githubusercontent.com/haruka98/ak_oneclick_installer/master/genz_003_005_01_04" -O "genz_003_005_01_04"
	chmod 777 genz_003_005_01_04
	. "/root/hxsy/genz_003_005_01_04"
	
	# config files
	wget --no-check-certificate "$MAINCONFIG" -O "config.zip"
	unzip "config.zip"
	rm -f "config.zip"
	sed -i "s/xxxxxxxx/$DBPASS/g" "setup.ini"
	
	# subservers
	wget --no-check-certificate --load-cookies "/tmp/cookies.txt" "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate "https://docs.google.com/uc?export=download&id=$SUBSERVERSID" -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=$SUBSERVERSID" -O "server.zip" && rm -rf "/tmp/cookies.txt"
	unzip "server.zip"
	rm -f "server.zip"
	sed -i "s/192.168.198.129/$EXTIP/g" "GatewayServer/setup.ini"
	sed -i "s/xxxxxxxx/$DBPASS/g" "GatewayServer/setup.ini"
	sed -i "s/192.168.198.129/$EXTIP/g" "TicketServer/setup.ini"
	sed -i "s/\xc0\xa8\xc6/$PATCHIP/g" "WorldServer/WorldServer"
	sed -i "s/\xc0\xa8\xc6/$PATCHIP/g" "ZoneServer/ZoneServer"
	
	# Data folder
	wget --no-check-certificate "$DATAFOLDER" -O "Data.zip"
	unzip "Data.zip" -d "Data"
	rm -f "Data.zip"
	
	# SQL files
	wget --no-check-certificate "$SQLFILES" -O "SQL.zip"
	unzip "SQL.zip" -d "SQL"
	rm -f "SQL.zip"
	
	# set permissions
	chmod 777 /root -R
	
	# install postgresql database
	service postgresql restart
	sudo -u postgres psql -c "create database ffaccount encoding 'UTF8' template template0; create database ffdb1 encoding 'UTF8' template template0; create database ffmember encoding 'UTF8' template template0; create database itemmall encoding 'UTF8' template template0;"
	sudo -u postgres psql -d ffaccount -c "\i '/root/hxsy/SQL/FFAccount.sql';"
	sudo -u postgres psql -d ffdb1 -c "\i '/root/hxsy/SQL/FFDB1.sql';"
	sudo -u postgres psql -d ffmember -c "\i '/root/hxsy/SQL/FFMember.sql';"
	sudo -u postgres psql -d itemmall -c "\i '/root/hxsy/SQL/Itemmall.sql';"
	sudo -u postgres psql -d ffaccount -c "UPDATE worlds SET ip = '$EXTIP' WHERE ip = '192.168.198.129';"
	sudo -u postgres psql -d ffdb1 -c "UPDATE serverstatus SET ext_address = '$EXTIP' WHERE ext_address = '192.168.198.129';"
	
	# remove server setup files
	rm -f genz_003_005_01_04
	
	#set the server date to 2013
	CURRENTYEAR=$(date | grep -Eo '[0-9]{4}')
	while [ $CURRENTYEAR -lt 2013 ] ; do
		date -s 'last year'
	done
	hwclock --systohc
	
	# display info screen
	echo "--------------------------------------------------"
	echo "Installation complete!"
	echo "--------------------------------------------------"
	echo "Server version: genz - 003.005.01.04"
	echo "Server IP: $EXTIP"
	echo "Postgresql version: $POSTGRESQLVERSION"
	echo "Database user: postgres"
	echo "Database password: $DBPASS"
	echo "Server path: /root/hxsy/"
	echo "Postgresql configuration path: /etc/postgresql/$POSTGRESQLVERSION/main/"
	echo "\nMake sure to thank genz and Eperty123!"
	echo "\nTo start the server, please run /root/hxsy/start"
	echo "To stop the server, please run /root/hxsy/stop"
fi
