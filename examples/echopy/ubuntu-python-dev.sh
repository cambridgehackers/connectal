#!/bin/sh

[ -f libpython2.7_2.7.11-11_armhf.deb ] || (
    wget http://ports.ubuntu.com/ubuntu-ports/pool/main/p/python2.7/libpython2.7_2.7.11-11_armhf.deb;
    ar x libpython2.7_2.7.11-11_armhf.deb;
    xzcat data.tar.xz | tar -xvf -
)
[ -f libpython2.7-dev_2.7.11-11_armhf.deb ] || (
    wget http://ports.ubuntu.com/ubuntu-ports/pool/main/p/python2.7/libpython2.7-dev_2.7.11-11_armhf.deb;
    ar x libpython2.7-dev_2.7.11-11_armhf.deb;
    xzcat data.tar.xz | tar -xvf - )
sed -i "s|#define _POSIX_C_SOURCE 200112L|/* _POSIX_C_SOURCE defined by features.h*/|" usr/include/arm-linux-gnueabihf/python2.7/pyconfig.h
sed -i "s|#define _XOPEN_SOURCE 600|/* _XOPEN_SOURCE defined by features.h*/|" usr/include/arm-linux-gnueabihf/python2.7/pyconfig.h
rm -f data.tar.xz control.tar.gz debian-binary
