#!/bin/sh
#
# $OpenBSD: check_smtpd.sh, 2018/07/12 01:23:21 anigma Exp $

PROCESS=$(rcctl ls stopped | grep -w 'smtpd' | wc -l)

# check if smtpd daemon is running
if [ $PROCESS -eq 1 ]; then
    # create symlinks for MariaDB socket
    mkdir -p /var/run/mysql
    ln -sf /var/www/var/run/mysql/mysql.sock /var/run/mysql/mysql.sock
    rcctl start smtpd
fi
