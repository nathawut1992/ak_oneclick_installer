#!/bin/sh

# define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
LRED='\033[1;31m'
LGREEN='\033[1;32m'
RC='\033[0m'

# make sure lists are up to date
apt-get -qq update

# install sudo in case it is missing
apt-get -qq install sudo -y

# make sure that ifconfig works
sudo apt-get -qq install net-tools

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

# select server version
echo "Select the version you want to install.\n1) yokohiro - 003.005.01.04 (recommended)\n2) genz - 003.005.01.04\n3) eperty123 - 003.005.01.04\n4) hycker - 003.005.01.03"
read AKVERSION

# make sure start / stop commands are working
sudo apt-get -qq install psmisc -y

# install wget in case it is missing
sudo apt-get -qq install wget -y

# install unzip in case it is missing
sudo apt-get -qq install unzip -y

# install postgresql in case it is missing
sudo apt-get -qq install postgresql -y
POSTGRESQLVERSION=$(psql --version | grep -Eo '[0-9].[0-9]' | head -n1)

# install pwgen in case it is missing
sudo apt-get -qq install pwgen -y

# generate database password
DBPASS=$(pwgen -s 32 1)

# setup postgresql
cd "/etc/postgresql/$POSTGRESQLVERSION/main"
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" postgresql.conf
sed -i "s+host    all             all             127.0.0.1/32            md5+host    all             all             0.0.0.0/0            md5+g" pg_hba.conf

# change password for the postgres account
sudo -u postgres psql -c "ALTER user postgres WITH password '$DBPASS';"

# ready ip for hexpatch
PATCHIP=$(printf '\\x%02x\\x%02x\\x%02x\n' $(echo "$EXTIP" | grep -o [0-9]* | head -n1) $(echo "$EXTIP" | grep -o [0-9]* | head -n2 | tail -n1) $(echo "$EXTIP" | grep -o [0-9]* | head -n3 | tail -n1))

# set version name
VERSIONNAME="NONE"

# --------------------------------------------------
# yokohiro - 003.005.01.04
# --------------------------------------------------
if [ "$AKVERSION" = 1 ] ; then
	cd "/root/hxsy"
	wget --no-check-certificate "https://raw.githubusercontent.com/haruka98/ak_oneclick_installer/master/yokohiro_003_005_01_04" -O "yokohiro_003_005_01_04"
	chmod 777 yokohiro_003_005_01_04
	. "/root/hxsy/yokohiro_003_005_01_04"
	
	# config files
	wget --no-check-certificate "$MAINCONFIG" -O "config.zip"
	unzip "config.zip"
	rm -f "config.zip"
	sed -i "s/123456/$DBPASS/g" "setup.ini"
	
	# subservers
	wget --no-check-certificate --load-cookies "/tmp/cookies.txt" "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate "https://docs.google.com/uc?export=download&id=$SUBSERVERSID" -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=$SUBSERVERSID" -O "server.zip" && rm -rf "/tmp/cookies.txt"
	unzip "server.zip"
	rm -f "server.zip"
	sed -i "s/192.168.0.33/$EXTIP/g" "GatewayServer/setup.ini"
	sed -i "s/123456/$DBPASS/g" "GatewayServer/setup.ini"
	sed -i "s/192.168.0.33/$EXTIP/g" "TicketServer/setup.ini"
	sed -i "s/\xff\x3d\xc0\xa8\x00/\xff\x3d$PATCHIP/g" "WorldServer101/WorldServer101"
	sed -i "s/\xff\x3d\xc0\xa8\x00/\xff\x3d$PATCHIP/g" "WorldServer102/WorldServer102"
	sed -i "s/\xff\x3d\xc0\xa8\x00/\xff\x3d$PATCHIP/g" "ZoneServer101/ZoneServer101"
	sed -i "s/\xff\x3d\xc0\xa8\x00/\xff\x3d$PATCHIP/g" "ZoneServer102/ZoneServer102"
	sed -i "s/10320/10321/g" "ZoneServer102/setup.ini"
	sed -i "s/20060/20061/g" "ZoneServer102/setup.ini"
	
	# Data folder
	wget --no-check-certificate --load-cookies "/tmp/cookies.txt" "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate "https://docs.google.com/uc?export=download&id=$DATAFOLDER" -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=$DATAFOLDER" -O "Data.zip" && rm -rf "/tmp/cookies.txt"
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
	sudo -u postgres psql -c "create database ffaccount encoding 'UTF8' template template0;"
	sudo -u postgres psql -c "create database ffdb1 encoding 'UTF8' template template0;"
	sudo -u postgres psql -c "create database ffmember encoding 'UTF8' template template0;"
	sudo -u postgres psql -c "create database itemmall encoding 'UTF8' template template0;"
	sudo -u postgres psql -d ffaccount -c "\i '/root/hxsy/SQL/FFAccount.sql';"
	sudo -u postgres psql -d ffdb1 -c "\i '/root/hxsy/SQL/FFDB1.sql';"
	sudo -u postgres psql -d ffmember -c "\i '/root/hxsy/SQL/FFMember.sql';"
	sudo -u postgres psql -d itemmall -c "\i '/root/hxsy/SQL/Itemmall.sql';"
	sudo -u postgres psql -d ffaccount -c "UPDATE worlds SET ip = '$EXTIP' WHERE ip = '192.168.198.129';"
	sudo -u postgres psql -d ffdb1 -c "UPDATE serverstatus SET ext_address = '$EXTIP' WHERE ext_address = '192.168.198.129';"
	
	# remove server setup files
	rm -f yokohiro_003_005_01_04
	
	#set the server date to 2013
	timedatectl set-ntp 0
	date -s "$(date +'2013%m%d %H:%M')"
	hwclock --systohc
	
	# setup info
	VERSIONNAME="yokohiro - 003.005.01.04"
	CREDITS="yokohiro, genz and Eperty123"
fi

# --------------------------------------------------
# genz - 003.005.01.04
# --------------------------------------------------
if [ "$AKVERSION" = 2 ] ; then
	cd "/root/hxsy"
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
	wget --no-check-certificate --load-cookies "/tmp/cookies.txt" "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate "https://docs.google.com/uc?export=download&id=$DATAFOLDER" -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=$DATAFOLDER" -O "Data.zip" && rm -rf "/tmp/cookies.txt"
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
	sudo -u postgres psql -c "create database ffaccount encoding 'UTF8' template template0;"
	sudo -u postgres psql -c "create database ffdb1 encoding 'UTF8' template template0;"
	sudo -u postgres psql -c "create database ffmember encoding 'UTF8' template template0;"
	sudo -u postgres psql -c "create database itemmall encoding 'UTF8' template template0;"
	sudo -u postgres psql -d ffaccount -c "\i '/root/hxsy/SQL/FFAccount.sql';"
	sudo -u postgres psql -d ffdb1 -c "\i '/root/hxsy/SQL/FFDB1.sql';"
	sudo -u postgres psql -d ffmember -c "\i '/root/hxsy/SQL/FFMember.sql';"
	sudo -u postgres psql -d itemmall -c "\i '/root/hxsy/SQL/Itemmall.sql';"
	sudo -u postgres psql -d ffaccount -c "UPDATE worlds SET ip = '$EXTIP' WHERE ip = '192.168.198.129';"
	sudo -u postgres psql -d ffdb1 -c "UPDATE serverstatus SET ext_address = '$EXTIP' WHERE ext_address = '192.168.198.129';"
	
	# remove server setup files
	rm -f genz_003_005_01_04
	
	#set the server date to 2013
	timedatectl set-ntp 0
	date -s "$(date +'2013%m%d %H:%M')"
	hwclock --systohc
	
	# setup info
	VERSIONNAME="genz - 003.005.01.04"
	CREDITS="genz and Eperty123"
fi

# --------------------------------------------------
# eperty123 - 003.005.01.04
# --------------------------------------------------
if [ "$AKVERSION" = 3 ] ; then
	cd "/root/hxsy"
	wget --no-check-certificate "https://raw.githubusercontent.com/haruka98/ak_oneclick_installer/master/eperty123_003_005_01_04" -O "eperty123_003_005_01_04"
	chmod 777 eperty123_003_005_01_04
	. "/root/hxsy/eperty123_003_005_01_04"
	
	# config files
	wget --no-check-certificate "$MAINCONFIG" -O "config.zip"
	unzip "config.zip"
	rm -f "config.zip"
	sed -i "s/123/$DBPASS/g" "setup.ini"
	
	# subservers
	wget --no-check-certificate --load-cookies "/tmp/cookies.txt" "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate "https://docs.google.com/uc?export=download&id=$SUBSERVERSID" -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=$SUBSERVERSID" -O "server.zip" && rm -rf "/tmp/cookies.txt"
	unzip "server.zip"
	rm -f "server.zip"
	sed -i "s/123/$DBPASS/g" "GatewayServer/setup.ini"
	sed -i "s/\xc0\xa8\xb2/$PATCHIP/g" "WorldServer/WorldServer"
	sed -i "s/\xc0\xa8\xb2/$PATCHIP/g" "ZoneServer/ZoneServer"
	
	# Data folder
	wget --no-check-certificate --load-cookies "/tmp/cookies.txt" "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate "https://docs.google.com/uc?export=download&id=$DATAFOLDER" -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=$DATAFOLDER" -O "Data.zip" && rm -rf "/tmp/cookies.txt"
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
	sudo -u postgres psql -c "create database FFAccount encoding 'UTF8' template template0;"
	sudo -u postgres psql -c "create database FFDB1 encoding 'UTF8' template template0;"
	sudo -u postgres psql -c "create database FFMember encoding 'UTF8' template template0;"
	sudo -u postgres psql -d ffaccount -c "\i '/root/hxsy/SQL/FFAccount.sql';"
	sudo -u postgres psql -d ffdb1 -c "\i '/root/hxsy/SQL/FFDB1.sql';"
	sudo -u postgres psql -d ffmember -c "\i '/root/hxsy/SQL/FFMember.sql';"
	sudo -u postgres psql -d ffaccount -c "UPDATE worlds SET ip = '$EXTIP' WHERE ip = '192.168.1.99';"
	sudo -u postgres psql -d ffdb1 -c "UPDATE serverstatus SET ext_address = '$EXTIP' WHERE ext_address = '192.168.1.99';"
	
	# remove server setup files
	rm -f eperty123_003_005_01_04
	
	#set the server date to 2013
	timedatectl set-ntp 0
	date -s "$(date +'2013%m%d %H:%M')"
	hwclock --systohc
	
	# setup info
	VERSIONNAME="eperty123 - 003.005.01.04"
	CREDITS="Eperty123"
fi

# --------------------------------------------------
# hycker - 003.005.01.03
# --------------------------------------------------
if [ "$AKVERSION" = 4 ] ; then
	cd "/root/hxsy"
	wget --no-check-certificate "https://raw.githubusercontent.com/haruka98/ak_oneclick_installer/master/hycker_003_005_01_03" -O "hycker_003_005_01_03"
	chmod 777 hycker_003_005_01_03
	. "/root/hxsy/hycker_003_005_01_03"
	
	# config files
	wget --no-check-certificate "$MAINCONFIG" -O "config.zip"
	unzip "config.zip"
	rm -f "config.zip"
	sed -i "s/hycker/$DBPASS/g" "setup.ini"
	
	# subservers
	wget --no-check-certificate --load-cookies "/tmp/cookies.txt" "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate "https://docs.google.com/uc?export=download&id=$SUBSERVERSID" -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=$SUBSERVERSID" -O "server.zip" && rm -rf "/tmp/cookies.txt"
	unzip "server.zip"
	rm -f "server.zip"
	sed -i "s/192.168.1.127/$EXTIP/g" "GatewayServer/setup.ini"
	sed -i "s/hycker/$DBPASS/g" "GatewayServer/setup.ini"
	sed -i "s/192.168.1.127/$EXTIP/g" "TicketServer/setup.ini"
	sed -i "s/\xc0\xa8\x01/$PATCHIP/g" "WorldServer101/WorldServer101"
	sed -i "s/\xc0\xa8\x01/$PATCHIP/g" "WorldServer102/WorldServer102"
	sed -i "s/\xc0\xa8\x01/$PATCHIP/g" "ZoneServer101/ZoneServer101"
	sed -i "s/\xc0\xa8\x01/$PATCHIP/g" "ZoneServer102/ZoneServer102"
	
	# Data folder
	wget --no-check-certificate --load-cookies "/tmp/cookies.txt" "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate "https://docs.google.com/uc?export=download&id=$DATAFOLDER" -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=$DATAFOLDER" -O "Data.zip" && rm -rf "/tmp/cookies.txt"
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
	sudo -u postgres psql -c "create database ffaccount encoding 'UTF8' template template0;"
	sudo -u postgres psql -c "create database ffdb1 encoding 'UTF8' template template0;"
	sudo -u postgres psql -c "create database ffmember encoding 'UTF8' template template0;"
	sudo -u postgres psql -d ffaccount -c "\i '/root/hxsy/SQL/ffaccount.sql';"
	sudo -u postgres psql -d ffdb1 -c "\i '/root/hxsy/SQL/ffdb1.sql';"
	sudo -u postgres psql -d ffmember -c "\i '/root/hxsy/SQL/ffmember.sql';"
	sudo -u postgres psql -d ffaccount -c "UPDATE worlds SET ip = '$EXTIP' WHERE ip = '192.168.1.127';"
	sudo -u postgres psql -d ffdb1 -c "UPDATE serverstatus SET ext_address = '$EXTIP' WHERE ext_address = '192.168.1.127';"
	
	# remove server setup files
	rm -f hycker_003_005_01_03
	
	#set the server date to 2013
	timedatectl set-ntp 0
	date -s "$(date +'2013%m%d %H:%M')"
	hwclock --systohc
	
	# setup info
	VERSIONNAME="hycker - 003.005.01.03"
	CREDITS="Hycker"
fi

if [ "$VERSIONNAME" = "NONE" ] ; then
	# display error
	echo "${RED}--------------------------------------------------"
	echo "Installation failed!"
	echo "--------------------------------------------------"
	echo "The selected version could not be installed. Please try again and choose a different version.${RC}"
else
	# display info screen
	echo "${LGREEN}--------------------------------------------------"
	echo "Installation complete!"
	echo "--------------------------------------------------"
	echo "Server version: $VERSIONNAME"
	echo "Server IP: $EXTIP"
	echo "Postgresql version: $POSTGRESQLVERSION"
	echo "Database user: postgres"
	echo "Database password: $DBPASS"
	echo "Server path: /root/hxsy/"
	echo "Postgresql configuration path: /etc/postgresql/$POSTGRESQLVERSION/main/"
	echo "\nMake sure to thank $CREDITS!"
	echo "\nTo start the server, please run /root/hxsy/start"
	echo "To stop the server, please run /root/hxsy/stop${RC}"
fi
