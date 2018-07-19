#!/bin/sh
#
# $OpenBSD: sftp.sh, 2017/09/15 10:12:43 anigma Exp $

# Failsafe to prevent from running without any arguments
if [ $# -eq 0 ]; then
	echo "No arguments provided!"
	exit 1
fi

# Parse the commandline parameters:
while [ ! -z "$1" ]; do
	case $1 in
		-u)
			USERNAME="$2"
			shift
			;;
		-d)
			DOMAIN="$2"
			shift
			;;
		-*)
			echo "Unsupported parameter '$1'!"
			exit 1
			;;
		*) # Everything else but switches (which start with '-') follows:
			echo "Usage: useradd_sftp.sh -u <username> -d <domain>"
			exit 1
			;;
	esac
shift # past argument or value
done

BASE=${BASE:-/var/www/htdocs}
DOMAIN=${DOMAIN:-purehype.no}

# Create random 16 char password and encrypt it with blowfish
RANDOM_PASSWORD=$(cat /dev/urandom | tr -dc "a-zA-Z0-9@#$&()?+" | fold -w 16 | head -n 1)
ENCRYPTED_PASSWORD=$(encrypt -b a $RANDOM_PASSWORD)

# Create user and directories based on commandline arguments
if [ ! -d $BASE/$USERNAME ]; then
	mkdir -p $BASE/$USERNAME/$DOMAIN
	useradd -d $BASE/$USERNAME -g sftp-only -s /sbin/nologin -p $ENCRYPTED_PASSWORD $USERNAME
	chown $USERNAME:sftp-only $BASE/$USERNAME/$DOMAIN
else
	echo "Directories already exists!"
	exit 1
fi

# Populate a text file with some useful information
cat > $(USERNAME).txt << EOF
Server: $DOMAIN
Bruker: $USERNAME
Passord: $RANDOM_PASSWORD
EOF
