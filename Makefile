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

export UDEV_RULES_DIR=/etc/udev/rules.d
UDEV_RULES=$(shell ls etc/udev/rules.d)
MODULES_LOAD_D_DIR=/etc/modules-load.d

all: pciedrivers scripts/syntax/parsetab.py

VERSION=15.03.1

pciedrivers:
	(cd drivers/pcieportal; make DRIVER_VERSION=$(VERSION))
	make -C pcie

pciedrivers-clean:
	(cd drivers/pcieportal; make clean)
	make -C pcie clean

ifneq ("$(DESTDIR)", "")
INSTALL_SHARED = install-shared
endif

install: $(INSTALL_SHARED)
	install -d -m755 $(DESTDIR)/$(UDEV_RULES_DIR)
	if [ -d $(DESTDIR)/$(MODULES_LOAD_D_DIR) ]; then \
	    for fname in ./$(MODULES_LOAD_D_DIR)/* ; do \
		install -m644 $$fname $(DESTDIR)$(MODULES_LOAD_D_DIR) ; \
	    done; \
	fi
	(cd drivers/pcieportal; make install)
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

dpkg:
	git archive --format=tar -o dpkg.tar --prefix=connectal-$(VERSION)/ HEAD
	tar -xf dpkg.tar
	rm -f connectal_*
	(cd connectal-$(VERSION); pwd; dh_make --createorig --email jamey.hicks@gmail.com --multi -c bsd; dpkg-buildpackage)

## PLY's home is http://www.dabeaz.com/ply/
install-dependences:
ifeq ($(shell uname), Darwin)
	port install asciidoc
	easy_install ply
else
	apt-get install asciidoc python-dev python-setuptools python-ply
	apt-get install libgmp3c2
endif
	easy_install blockdiag seqdiag actdiag nwdiag libusb1
        wget https://asciidoc-diag-filter.googlecode.com/files/diag_filter.zip
	asciidoc --filter install diag_filter.zip
	wget http://laurent-laville.org/asciidoc/bootstrap/bootstrap-3.3.0.zip
	asciidoc --backend install bootstrap-3.3.0.zip

BOARD=zedboard

scripts/syntax/parsetab.py: scripts/syntax.py
	[ -e out ] || mkdir out
	python scripts/syntax.py

#################################################################################################
# tests

memtests =  memread_manyclients  \
            memwrite_manyclients \
            memread_manyclients128  \
            memwrite_manyclients128 


zr_examples = gyro_simple \
            maxsonar_simple \
            hbridge_simple \
            zedboard_robot

matmultests2 = testmm8.8.2       \
	    testmm16.16.2        \
	    testmm32.32.2        \
	    testmm32.16.2        \
	    testmm4.4.2          \
	    testmm4.2.2          \
	    testmm2.4.2          \
	    testmm2.2.2          

matmultests4 = testmm16.16.4     \
	    testmm8.8.4          \
	    testmm4.4.4        

matmultests = $(matmultests2)    \
	    $(matmultests4)


rbmtests2 = testrbm2.2.2         \
            testrbm8.8.2         \
            testrbm16.16.2

tests    =  $(memtests)          \
	    $(matmultests)       \
            $(rbmtests2)         \
	    ipcperf              \
	    memread_manual       \
	    simple_manual

#################################################################################################
# examples

examples =  echo                 \
	    echojson             \
	    echosoft             \
	    aurora               \
	    hdmidisplay          \
	    led2                 \
	    alterajtaguart       \
            memcpy               \
            memlatency           \
            memread              \
	    memwrite             \
            memrw                \
            memread128           \
            memread2             \
            pipe_mul             \
            pipe_mul2            \
            printf               \
            simple               \
            strstr               \
	    ring                 \
	    perf                 \
	    nandsim              \
	    algo1_nandsim        \
	    strstr_nandsim       \
            flowcontrol          \
            bluescope            \
            bluescopeevent       \
            bluescopeeventpio    \
	    splice               \
	    maxcommonsubseq      \
	    smithwaterman        \
	    serialconfig         \
	    noc                  \
	    noc2d                \
	    fib                  \
	    xsim-echo            \
	    imageon              \
	    imageonfb            \
	    fmcomms1		 \
	    channelselect	 \
	    tiny3		 \
	    ptest                \
            bscan                \
            memread_4m           \
            memwrite_4m          \
	    matmul               \
	    rbm                  \
            yuv                  \
            gyro_simple          \
            maxsonar_simple      \
            hbridge_simple       \
            zedboard_robot

memexamples =  memcpy            \
            memread              \
	    memwrite             \
            memrw                \
	    memread2             

zmemexamples = memread_4m        \
            memwrite_4m          \
            $(memexamples)        

bsimalllist =     \
    examples/echo \
    examples/memcpy \
    examples/memlatency \
    examples/memread \
    examples/memread2 \
    examples/memread_4m \
    examples/memrw \
    examples/memwrite \
    examples/memwrite_4m \
    examples/nandsim \
    examples/pipe_mul \
    examples/pipe_mul2 \
    examples/simple \
    examples/strstr \
    examples/matmul \
    examples/rbm \
    examples/yuv \
    tests/memread_manual \
    tests/simple_manual \
    tests/testmm4.2.2 \
    tests/testmm4.4.2 \
    tests/testmm4.4.4 \
    tests/testmm8.8.2 \
    tests/testmm8.8.4 \

cppalllist =     $(bsimalllist) \
    examples/bscan \
    examples/fib \
    examples/flowcontrol \
    examples/hdmidisplay \
    examples/imageon \
    examples/maxcommonsubseq \
    examples/memread128 \
    examples/noc \
    examples/noc2d \
    examples/perf \
    examples/printf \
    examples/ring \
    examples/serialconfig \
    examples/smithwaterman \
    examples/splice \
    examples/xsim-echo \
    tests/testmm16.16.2 \
    tests/testmm16.16.4 \
    tests/testmm2.2.2 \
    tests/testmm2.4.2 \

allarchlist = ac701 zedboard zc702 zc706 kc705 vc707 zynq100 v2000t bluesim miniitx100 de5 htg4 vsim parallella xsim zybo

#################################################################################################
# gdb

%.gdb:
	make CONNECTAL_DEBUG=1 $*

#################################################################################################
define TARGET_RULE
$1tests := $(addprefix examples/, $(addsuffix .$1, $(examples))) \
	     $(addprefix tests/, $(addsuffix .$1, $(tests)))

$$($1tests):
	rm -fr $$(basename $$@)/$1
ifeq ("$1","xsim")
	make BOARD=bluesim -C $$(basename $$@) xsim
else
	make BOARD=$1 -C $$(basename $$@) --no-print-directory all
endif

$1runs := $(addprefix examples/, $(addsuffix .$1run, $(examples))) \
	    $(addprefix tests/, $(addsuffix .$1run, $(tests)))

# RUNPARAM=ipaddr is an optional argument if you already know the IP of the $1
$$($1runs):
ifeq ("$1","xsim")
	make BOARD=bluesim -C $$(basename $$@) xsimrun
else
	make BOARD=$1 --no-print-directory -C $$(basename $$@)/$1 run
endif

$1cpps := $(addprefix examples/, $(addsuffix .$1cpp, $(examples))) \
	    $(addprefix tests/, $(addsuffix .$1cpp, $(tests)))

$$($1cpps):
	rm -fr $$(basename $$@)/$1
ifeq ("$1","bluesim")
	make BOARD=$1 --no-print-directory -C $$(basename $$@) bsim_exe
else ifneq ("$1","xsim")
	make BOARD=$1 --no-print-directory -C $$(basename $$@) exe
endif

endef

$(foreach archname,$(allarchlist), $(eval $(call TARGET_RULE,$(archname))))

#################################################################################################
# memexamples

memexamples.zedboard: $(addprefix examples/, $(addsuffix .zedboard, $(memexamples)))

memexamples.kc705: $(addprefix examples/, $(addsuffix .kc705, $(memexamples)))
memexamples.kc705run: $(addprefix examples/, $(addsuffix .kc705run, $(memexamples)))

memexamples.bluesim: $(addprefix examples/, $(addsuffix .bluesim, $(memexamples)))

memexamples.bluesimrun: $(addprefix examples/, $(addsuffix .bluesimrun, $(memexamples)))

#################################################################################################
# zmemexamples

zmemexamples.zedboard: $(addprefix examples/, $(addsuffix .zedboard, $(zmemexamples)))

zmemexamples.bluesim: $(addprefix examples/, $(addsuffix .bluesim, $(zmemexamples)))

zmemexamples.bluesimrun: $(addprefix examples/, $(addsuffix .bluesimrun, $(zmemexamples)))

#################################################################################################
# tests

tests.bluesim:  $(addprefix tests/, $(addsuffix .bluesim, $(tests)))
tests.bluesimrun:  $(addprefix tests/, $(addsuffix .bluesimrun, $(tests)))
tests.kc705:  $(addprefix tests/, $(addsuffix .kc705, $(tests)))
tests.vc707:  $(addprefix tests/, $(addsuffix .vc707, $(tests)))

#################################################################################################
# matmultests

matmultests.bluesim:  $(addprefix tests/, $(addsuffix .bluesim, $(matmultests)))
matmultests.bluesimrun:  $(addprefix tests/, $(addsuffix .bluesimrun, $(matmultests)))
matmultests.bluesimcpp:  $(addprefix tests/, $(addsuffix .bluesimcpp, $(matmultests)))
matmultests.kc705:  $(addprefix tests/, $(addsuffix .kc705, $(matmultests)))
matmultests.vc707:  $(addprefix tests/, $(addsuffix .vc707, $(matmultests)))
matmultests.zc706:  $(addprefix tests/, $(addsuffix .zc706, $(matmultests2)))

#################################################################################################
# misc


zr_examples.zedboard: $(addprefix examples/, $(addsuffix .zedboard, $(zr_examples)))

android_exetests = $(addprefix examples/, $(addsuffix .android_exe, $(examples)))
android_exetests: $(android_exetests)

$(android_exetests):
	make BOARD=zedboard -C $(basename $@) exe

# For the parallella build to work, the cross compilers need to be in your path
# and the parallella kernel needs to be parallel to connectal and built
parallelladrivers:
	(cd drivers/zynqportal/; DRIVER_VERSION=$(VERSION) CROSS_COMPILE=arm-linux-gnueabihf- DEVICE_XILINX_KERNEL=`pwd`/../../../parallella-linux/ make parallellazynqportal.ko)
	(cd drivers/portalmem/; DRIVER_VERSION=$(VERSION) CROSS_COMPILE=arm-linux-gnueabihf- DEVICE_XILINX_KERNEL=`pwd`/../../../parallella-linux/ make parallellaportalmem.ko)

parallelladrivers-clean:
	(cd drivers/zynqportal/;  CROSS_COMPILE=arm-linux-gnueabihf- DEVICE_XILINX_KERNEL=`pwd`/../../../linux-xlnx/ make clean)
	(cd drivers/portalmem/;   CROSS_COMPILE=arm-linux-gnueabihf- DEVICE_XILINX_KERNEL=`pwd`/../../../linux-xlnx/ make clean)

zynqdrivers:
	(cd drivers/zynqportal/; DRIVER_VERSION=$(VERSION) DEVICE_XILINX_KERNEL=`pwd`/../../../linux-xlnx/ make zynqportal.ko)
	(cd drivers/portalmem/;  DRIVER_VERSION=$(VERSION) DEVICE_XILINX_KERNEL=`pwd`/../../../linux-xlnx/ make portalmem.ko)

zynqdrivers-clean:
	(cd drivers/zynqportal/; DEVICE_XILINX_KERNEL=`pwd`/../../../linux-xlnx/ make clean)
	(cd drivers/portalmem/;  DEVICE_XILINX_KERNEL=`pwd`/../../../linux-xlnx/ make clean)

zynqdrivers-install:
	cp drivers/zynqportal/zynqportal.ko drivers/portalmem/portalmem.ko ../zynq-boot/imagefiles/

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

#################################################################################################

#xilinx/pcie_7x_gen1x8: scripts/generate-pcie-gen1x8.tcl
#	rm -fr project_pcie_gen1x8
#	vivado -mode batch -source scripts/generate-pcie-gen1x8.tcl
#	mv ./project_pcie_gen1x8/project_pcie_gen1x8.srcs/sources_1/ip/pcie_7x_0 xilinx/pcie_7x_gen1x8
#	rm -fr ./project_pcie_gen1x8

cppruns = $(addsuffix .cpp, $(cppalllist))

cppruns: $(cppruns)

$(cppruns):
	@for archname in $(allarchlist) ; do  \
	   set -e ; \
	   echo make $(basename $@)."$$archname";  \
	   make  --no-print-directory $(basename $@)."$$archname"cpp;  \
	done

cppall:
	@for testname in $(cppalllist) ; do  \
	   set -e ; \
	   make $$testname.cpp;  \
	done

bsimall:
	@for testname in $(bsimalllist) ; do  \
	   set -e ; \
	   echo make $$testname.bluesim;  \
	   make  --no-print-directory $$testname.bluesim;  \
	   echo make $$testname.bluesimrun;  \
	   make  --no-print-directory $$testname.bluesimrun;  \
	done

distclean:
	for archname in $(allarchlist) ; do  \
	   rm -rf examples/*/"$$archname" tests/*/"$$archname"; \
	done
	rm -rf drivers/*/.tmp_versions tests/memread_manual/kernel/.tmp_versions/
	rm -rf pcie/connectalutil/connectalutil tests/memread_manual/kernel/bsim_relay
	rm -rf out/ exit.status cpp/*.o scripts/*.pyc
	rm -rf tests/*/train-images-idx3-ubyte examples/*/train-images-idx3-ubyte
	rm -f drivers/pcieportal/.*.o.cmd drivers/pcieportal/.*.ko.cmd
	rm -f drivers/portalmem/.*.o.cmd drivers/portalmem/.*.ko.cmd
	rm -f drivers/zynqportal/.*.o.cmd drivers/zynqportal/.*.ko.cmd
	rm -rf doc/library/build/ examples/rbm/datasets/
	rm -f doc/library/source/devguide/connectalbuild-1.png

