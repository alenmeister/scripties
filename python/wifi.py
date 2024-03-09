#!/usr/bin/python3

import argparse
import fileinput
import hashlib
import re
import subprocess
import time


def store_wpa_entries(ssid: str, passphrase: str):
    # Use PBKDF2 with SHA-1 to generate a 256-bit PSK
    psk = hashlib.pbkdf2_hmac('sha1', passphrase.encode(), ssid.encode(), 4096, dklen=32)

    file_path = '/etc/network/interfaces'

    ssid_pattern = re.compile(r'(?<=wpa-ssid\s).*')
    psk_pattern = re.compile(r'(?<=wpa-psk\s).*')

    try:
        with fileinput.FileInput(file_path, inplace=True, backup='.bak') as file:
            for line in file:
                if ssid_pattern.search(line):
                    line = re.sub(ssid_pattern, ssid, line)
                elif psk_pattern.search(line):
                    line = re.sub(psk_pattern, psk.hex(), line)
                print(line, end='')
    except PermissionError:
        print(f'Permission denied while access {file_path}\n' 
              f'Execute with an elevated user (hint: doas)')


def restart_networking_service():
    try:
        subprocess.Popen(
            ['systemctl', 'restart', 'networking.service'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )

        # Give background job a few seconds to process
        time.sleep(2)

        while True:
            status = subprocess.run(
                ['systemctl', 'is-active', 'networking.service'], 
                capture_output=True, 
                text=True
            )
            
            is_active = status.stdout.strip().lower() == 'active'

            if is_active:
                print('The networking service is active')
                break
            else:
                print(f'Networking service status: {status.stdout.strip()}')

            # Wait for a short interval before checking again
            time.sleep(2)
    except subprocess.CalledProcessError as err:
        print(f'Something went wrong during restart of networking service:\n {err}')


def main():
    parser = argparse.ArgumentParser(description='Connect to a wireless network')
    parser.add_argument('-c', '--connect', nargs=2, metavar=('<SSID>', '<passphrase>'),
                        help='Specify SSID and passphrase for the wireless network')

    args = parser.parse_args()

    if args.connect:
        ssid, passphrase = args.connect
        store_wpa_entries(ssid, passphrase)
        restart_service()
    else:
        parser.print_help()


if __name__ == '__main__':
    main()
