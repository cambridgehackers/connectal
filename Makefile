# Copyright (c) 2014 Quanta Research Cambridge, Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
#

include Makefile.version

export UDEV_RULES_DIR=/etc/udev/rules.d
UDEV_RULES=$(shell ls etc/udev/rules.d)
MODULES_LOAD_D_DIR=/etc/modules-load.d

all: pciedrivers scripts/syntax/parsetab.py
	echo version "$(VERSION)"

pciedrivers:
	(cd drivers/pcieportal; make)
	make -C pcie

pciedrivers-clean:
	(cd drivers/pcieportal; make clean)
	make -C pcie clean

ifneq ("$(DESTDIR)", "")
INSTALL_SHARED = install-shared
endif

install: $(INSTALL_SHARED)
	install -d -m755 $(DESTDIR)/$(UDEV_RULES_DIR) $(DESTDIR)/etc/modules-load.d
	if [ -d $(DESTDIR)/$(MODULES_LOAD_D_DIR) ]; then \
	    for fname in ./$(MODULES_LOAD_D_DIR)/* ; do \
		install -m644 $$fname $(DESTDIR)$(MODULES_LOAD_D_DIR) ; \
	    done; \
	fi
	echo 'Installing from' $(CURDIR)
	(cd drivers/pcieportal; CONNECTALDIR=$(CURDIR) make install)
	install -m644 etc/modules-load.d/connectal.conf $(DESTDIR)/etc/modules-load.d
	make -C pcie install
	install -d -m755 $(DESTDIR)$(UDEV_RULES_DIR)
	for fname in $(UDEV_RULES) ; do \
	    install -m644 etc/udev/rules.d/$$fname $(DESTDIR)$(UDEV_RULES_DIR) ; \
	done
ifeq ( _$(DESTDIR), _)
	service udev restart;
	rmmod portalmem;
	rmmod pcieportal;
	modprobe portalmem;
	modprobe pcieportal;
endif

INSTALL_DIRS = $(shell ls | grep -v debian)

install-shared:
	find $(INSTALL_DIRS) -type d -exec install -d -m755 $(DESTDIR)/usr/share/connectal/{} \; -print
	find $(INSTALL_DIRS) -type f -exec install -m644 {} $(DESTDIR)/usr/share/connectal/{} \; -print
	chmod agu+rx $(DESTDIR)/usr/share/connectal/scripts/*

uninstall:
	for fname in ./$(MODULES_LOAD_D_DIR)/* ; do \
	    rm -vf $(MODULES_LOAD_D_DIR)/`basename $$fname` ; \
	done;
	(cd drivers/pcieportal; make uninstall)
	make -C pcie/connectalutil uninstall
	for fname in $(UDEV_RULES) ; do \
	    rm -f $(UDEV_RULES_DIR)/$$fname ; \
	done
	service udev restart

docs:
	doxygen scripts/Doxyfile

spkg:
	git clean -fdx
	git checkout debian
	sed -i s/precise/precise/g debian/changelog
	gbp buildpackage --git-upstream-branch=master --git-debian-branch=ubuntu --git-ignore-new -S -tc '--git-upstream-tag=v%(version)s'
	git checkout debian
	sed -i s/precise/trusty/g debian/changelog
	gbp buildpackage --git-upstream-branch=master --git-debian-branch=ubuntu --git-ignore-new -S -tc '--git-upstream-tag=v%(version)s'
	git checkout debian
	sed -i s/precise/xenial/g debian/changelog
	gbp buildpackage --git-upstream-branch=master --git-debian-branch=ubuntu --git-ignore-new -S -tc '--git-upstream-tag=v%(version)s'
	git checkout debian
	sed -i s/precise/artful/g debian/changelog
	gbp buildpackage --git-upstream-branch=master --git-debian-branch=ubuntu --git-ignore-new -S -tc '--git-upstream-tag=v%(version)s'
	git checkout debian

upload:
	git push origin v$(VERSION)
	(cd  ../obs/home:jameyhicks:connectaldeb/connectal/; osc rm * || true)
	cp -v ../connectal_$(VERSION)*stable*.diff.gz ../connectal_$(VERSION)*stable*.dsc ../connectal_$(VERSION)*.orig.tar.gz ../obs/home:jameyhicks:connectaldeb/connectal/
	rm -fv ../connectal_$(VERSION)*stable*
	dput ppa:jamey-hicks/connectal ../connectal_$(VERSION)-*_source.changes
	(cd ../obs/home:jameyhicks:connectaldeb/connectal/; osc add *; osc commit -m $(VERSION) )
	(cd ../obs/home:jameyhicks:connectal/connectal; sed -i "s/>v.....</>v$(VERSION)</" _service; osc commit -m "v$(VERSION)" )

## PLY's home is http://www.dabeaz.com/ply/
install-dependencies: install-dependences

install-dependences:
ifeq ($(shell uname), Darwin)
	port install asciidoc
	easy_install ply
else
	if [ -f /usr/bin/yum ] ; then yum install gmp strace python-argparse python-ply python-gevent; else apt-get install libgmp10 strace python-ply python-gevent; fi
	if [ -f /usr/lib/x86_64-linux-gnu/libgmp.so ] ; then ln -sf /usr/lib/x86_64-linux-gnu/libgmp.so /usr/lib/x86_64-linux-gnu/libgmp.so.3 ; fi
	if [ ! -f /usr/lib64/libgmp.so.3 ] && [ -f /usr/lib64/libgmp.so.10 ] ; then ln -s /usr/lib64/libgmp.so.10 /usr/lib64/libgmp.so.3; fi
endif

install-python-example-dependences:
	sudo apt-get install python-dev

install-doc-dependences:
	apt-get install asciidoc python-setuptools
	easy_install blockdiag seqdiag actdiag nwdiag libusb1
	wget https://asciidoc-diag-filter.googlecode.com/files/diag_filter.zip
	asciidoc --filter install diag_filter.zip
	wget http://laurent-laville.org/asciidoc/bootstrap/bootstrap-3.3.0.zip
	asciidoc --backend install bootstrap-3.3.0.zip

BOARD=zedboard

scripts/syntax/parsetab.py: scripts/syntax.py
	[ -e out ] || mkdir out
	python3 scripts/syntax.py

allarchlist = ac701 zedboard zc702 zc706 kc705 vc707 zynq100 v2000t bluesim miniitx100 de5 htg4 vsim parallella xsim zybo kc705g2 vc707g2

#################################################################################################

KROOT_ZYNQ := $(PWD)/../linux-xlnx/

zynqdrivers:
	(cd drivers/zynqportal/; KROOT=$(KROOT_ZYNQ) make zynqportal.ko)
	(cd drivers/portalmem/;  KROOT=$(KROOT_ZYNQ) make portalmem.ko)

zynqdrivers-clean:
	(cd drivers/zynqportal/; KROOT=$(KROOT_ZYNQ) make clean)
	(cd drivers/portalmem/;  KROOT=$(KROOT_ZYNQ) make clean)

zynqdrivers-install:
	install -d -m755 $(DESTDIR)/usr/share/connectal-zynqdrivers/
	install -m644 drivers/zynqportal/zynqportal.ko drivers/portalmem/portalmem.ko $(DESTDIR)/usr/share/connectal-zynqdrivers/

# For the parallella build to work, the cross compilers need to be in your path
# and the parallella kernel needs to be parallel to connectal and built
KROOT_PAR  := $(PWD)/../parallella-linux/
parallelladrivers:
	(cd drivers/zynqportal/; CROSS_COMPILE=arm-linux-gnueabihf- KROOT=$(KROOT_PAR) make parallellazynqportal.ko)
	(cd drivers/portalmem/; CROSS_COMPILE=arm-linux-gnueabihf- KROOT=$(KROOT_PAR) make parallellaportalmem.ko)

parallelladrivers-clean:
	(cd drivers/zynqportal/;  CROSS_COMPILE=arm-linux-gnueabihf- KROOT=$(KROOT_ZYNQ) make clean)
	(cd drivers/portalmem/;   CROSS_COMPILE=arm-linux-gnueabihf- KROOT=$(KROOT_ZYNQ) make clean)

RUNPARAMTEMP=$(subst :, ,$(RUNPARAM):5555)
RUNIP=$(wordlist 1,1,$(RUNPARAMTEMP))
RUNPORT=$(wordlist 2,2,$(RUNPARAMTEMP))

zynqdrivers-adb:
	adb connect $(RUNPARAM)
	adb -s $(RUNIP):$(RUNPORT) shell pwd || true
	adb connect $(RUNPARAM)
	adb -s $(RUNIP):$(RUNPORT) root || true
	sleep 1
	adb connect $(RUNPARAM)
	adb -s $(RUNIP):$(RUNPORT) push drivers/zynqportal/zynqportal.ko /mnt/sdcard
	adb -s $(RUNIP):$(RUNPORT) push drivers/portalmem/portalmem.ko /mnt/sdcard
	adb -s $(RUNIP):$(RUNPORT) shell rmmod zynqportal
	adb -s $(RUNIP):$(RUNPORT) shell rmmod portalmem
	adb -s $(RUNIP):$(RUNPORT) shell insmod /mnt/sdcard/zynqportal.ko
	adb -s $(RUNIP):$(RUNPORT) shell insmod /mnt/sdcard/portalmem.ko

connectalspi-clean:
	(cd drivers/connectalspi/; KROOT=$(KROOT_ZYNQ) make clean)

connectalspi:
	(cd drivers/connectalspi/; KROOT=$(KROOT_ZYNQ) make connectalspi.ko)

connectalspi-adb: 
	adb connect $(RUNPARAM)
	adb -s $(RUNIP):$(RUNPORT) shell pwd || true
	adb connect $(RUNPARAM)
	adb -s $(RUNIP):$(RUNPORT) root || true
	sleep 1
	adb connect $(RUNPARAM)
	adb -s $(RUNIP):$(RUNPORT) push drivers/connectalspi/connectalspi.ko /mnt/sdcard
	adb -s $(RUNIP):$(RUNPORT) shell rmmod connectalspi
	adb -s $(RUNIP):$(RUNPORT) shell insmod /mnt/sdcard/connectalspi.ko
	adb -s $(RUNIP):$(RUNPORT) shell chmod 777 /dev/spi*

distclean: pciedrivers-clean
	for archname in $(allarchlist) ; do  \
	   rm -rf examples/*/"$$archname" tests/*/"$$archname"; \
	done
	rm -rf pcie/connectalutil/connectalutil tests/memread_manual/kernel/bsim_relay
	rm -rf out/ exit.status cpp/*.o scripts/*.pyc
	rm -rf tests/*/train-images-idx3-ubyte examples/*/train-images-idx3-ubyte
	rm -rf doc/library/build/ examples/rbm/datasets/
	rm -f doc/library/source/devguide/connectalbuild-1.png
	rm -rf tests/partial/variant2
