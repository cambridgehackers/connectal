#!/bin/sh

for path in p/python2.7/libpython2.7_2.7.11-7ubuntu1_armhf p/python2.7/libpython2.7-dev_2.7.11-7ubuntu1_armhf libj/libjsoncpp/libjsoncpp1_1.7.2-1_armhf libj/libjsoncpp/libjsoncpp-dev_1.7.2-1_armhf; do
    pkg=`basename $path`
    [ -f $pkg.deb ] || (
	wget http://ports.ubuntu.com/ubuntu-ports/pool/main/$path.deb;
	ar x $pkg.deb;
	xzcat data.tar.xz | tar -xvf -
    )
done
sed -i "s|#define _POSIX_C_SOURCE 200112L|/* _POSIX_C_SOURCE defined by features.h*/|" usr/include/arm-linux-gnueabihf/python2.7/pyconfig.h
sed -i "s|#define _XOPEN_SOURCE 600|/* _XOPEN_SOURCE defined by features.h*/|" usr/include/arm-linux-gnueabihf/python2.7/pyconfig.h
rm -f data.tar.xz control.tar.gz debian-binary
