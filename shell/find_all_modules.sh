#!/bin/bash
for x in `find /sys/ -name modalias -exec cat {} \;`; do
  /sbin/modprobe --config /dev/null --show-depends $x ;
done | rev | cut -f 1 -d '/' | rev | sort -u
