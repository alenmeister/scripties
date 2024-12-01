#!/bin/sh

PROCESS=$(rcctl ls stopped | grep -w 'smtpd' | wc -l)

# Check if the SMTPD daemon is running
if [ $PROCESS -eq 1 ]; then
    # Create symlinks for the MariaDB socket
    mkdir -p /var/run/mysql
    ln -sf /var/www/var/run/mysql/mysql.sock /var/run/mysql/mysql.sock
    
    # Start the SMTPD daemon
    rcctl start smtpd
fi
