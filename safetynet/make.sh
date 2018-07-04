#!/bin/bash

PATH=$PATH
echo $PATH

FILENAME="com.nito.safetynet-1.0_appletvos_arm64.deb"

make clean
make all
recursiveRemove .DS_Store
fakeroot dpkg-deb -b layout $FILENAME
scp $FILENAME root@apple-tv.local:~
ssh root@apple-tv.local "export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin/X11:/usr/games ; /usr/bin/dpkg -i $FILENAME"

#scp build/usr/bin/safetyNet/safetynet root@apple-tv.local:~
