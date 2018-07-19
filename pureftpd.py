#!/usr/local/bin/python2.7
# -*- coding: utf-8 -*-

__author__ = 'Alen Mistric <anigma@purehype.no>'
__copyright__ = 'Copyright 2017 Alen Mistric'
__license__ = 'ISC'

import argparse
import errno
import os
import pymysql
import pysodium
import random

def check_directory(homedir, domain):
    path = os.path.join(homedir, domain)
    base = os.path.dirname(path)

    if not os.path.exists(path):
        try:
            os.makedirs(path)
            os.chown(base, 642, 642)
            os.chown(path, 642, 67)
        except OSError as e:
            if e.errno != errno.EEXIST:
                raise
            pass
    else:
        print('%s %s' % (path, 'already exists.'))

def randomize_password(length=16):
    chars = ["abcdefghjklmnpqrstuvwxyz", "0987654321", "ABCDEFGHJKLMNPQRSTUVWXYZ", "!@#$%^&*)(-_}{"]
    cleartext = ''

    while len(cleartext) < length:
        randChars = random.choice(chars)
        cleartext = cleartext + random.choice(randChars)
    return cleartext

def create_file(username, password):
    current = os.path.dirname(os.path.abspath(__file__))
    path = os.path.join(current, username) + '.txt'

    dict = {'Username': username, 'Password': password}

    with open(path, 'w') as file:
        for key, value in dict.items():
            file.write('{0}: {1}'.format(key, value))
            file.write('\n')
    os.chmod(path, 0750)

def sql_insert(username, password, status, homedir):
    query = "INSERT INTO users (Username, Password, Status, Directory) VALUES (%s, %s, %s, %s)"
    args = (username, password, status, homedir)

    try:
        db = pymysql.connect(host='localhost', user='pureftpd', password='foo', db='pureftpd')

        with db.cursor() as cursor:
            cursor.execute(query, args)
            # No autocommit by default
            db.commit()

    except pymysql.Error as e:
        db.rollback()
        raise

    finally:
        db.close()

def main():
    parser = argparse.ArgumentParser()

    parser.add_argument('-u', '--username', action='store', dest='username', required=True)
    parser.add_argument('-m', '--homedir', action='store', dest='directory', required=True)
    parser.add_argument('-d', '--domain', action='store', dest='domain')
    parser.add_argument('-i', '--inactive', action='store_true', dest='inactive', help='Removes authentication privileges')
    args = parser.parse_args()

    cleartext = randomize_password()
    password = pysodium.crypto_pwhash_scryptsalsa208sha256_str(cleartext, 1, 1)

    if args.inactive is True:
        sql_insert(args.username, password, '0', args.directory)
        print('New FTP/TLS user created without authentication privileges.\n' + '%s %s' % ('See details for more information:', args.username + '.txt'))
    else:
        sql_insert(args.username, password, '1', args.directory)
        print('New FTP/TLS user created.\n' + '%s %s' % ('See details for more information:', args.username + '.txt'))

    if args.domain is not None:
        check_directory(args.directory, args.domain)

    create_file(args.username, cleartext)

if __name__ == '__main__':
    main()
