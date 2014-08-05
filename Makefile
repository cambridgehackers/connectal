
export UDEV_RULES_DIR=/etc/udev/rules.d
UDEV_RULES=$(shell ls etc/udev/rules.d)

all: pciedrivers

pciedrivers:
	(cd drivers/pcieportal; make)
	make -C pcie/xbsvutil

pciedrivers-clean:
	(cd drivers/pcieportal; make clean)
	make -C pcie/xbsvutil clean

install:
	(cd drivers/pcieportal; make install)
	make -C pcie/xbsvutil install
	for fname in $(UDEV_RULES) ; do \
	    install -m644 etc/udev/rules.d/$$fname $(UDEV_RULES_DIR) ; \
	done
	service udev restart
	-rmmod portalmem
	-rmmod pcieportal 
	-modprobe portalmem 
	-modprobe pcieportal

uninstall:
	(cd drivers/pcieportal; make uninstall)
	make -C pcie/xbsvutil uninstall
	for fname in $(UDEV_RULES) ; do \
	    rm -f $(UDEV_RULES_DIR)/$$fname ; \
	done
	service udev restart

docs:
	doxygen Doxyfile

## PLY's home is http://www.dabeaz.com/ply/
install-dependences:
ifeq ($(shell uname), Darwin)
	port install asciidoc
	easy_install ply
else
	apt-get install asciidoc python-dev python-setuptools python-ply
	apt-get install libgmp3c2
endif
	easy_install blockdiag seqdiag actdiag nwdiag
        wget https://asciidoc-diag-filter.googlecode.com/files/diag_filter.zip
	asciidoc --filter install diag_filter.zip
	wget http://laurent-laville.org/asciidoc/bootstrap/bootstrap-3.3.0.zip
	asciidoc --backend install bootstrap-3.3.0.zip

BOARD=zedboard

parsetab.py: syntax.py
	python syntax.py

#################################################################################################
# tests

memtests =  memread_manyclients  \
            memwrite_manyclients 

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

tests    =  $(memtests)          \
	    $(matmultests)       \
	    memread_manual       \
	    simple_manual

#################################################################################################
# examples

examples =  echo                 \
	    hdmidisplay          \
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
            flowcontrol          \
            bluescope            \
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
            bscan                \
            memread_4m           \
            memwrite_4m          \
	    matmul               \
            yuv                  

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

allarchlist = bluesim zedboard vc707 

#################################################################################################
# gdb

%.gdb:
	make XBSV_DEBUG=1 $*

#################################################################################################
# bluesim

bluesimtests = $(addprefix examples/, $(addsuffix .bluesim, $(examples))) \
	       $(addprefix tests/, $(addsuffix .bluesim, $(tests)))
bluesimtests: $(bluesimtests)


$(bluesimtests):
	rm -fr $(basename $@)/bluesim
	make BOARD=bluesim -C $(basename $@) --no-print-directory exe


bluesimruns = $(addprefix examples/, $(addsuffix .bluesimrun, $(examples))) \
	      $(addprefix tests/, $(addsuffix .bluesimrun, $(tests)))
bluesimruns: $(bluesimruns)

$(bluesimruns):
	(cd $(basename $@)/bluesim; make --no-print-directory run)

bluesimcpps = $(addprefix examples/, $(addsuffix .bluesimcpp, $(examples))) \
	      $(addprefix tests/, $(addsuffix .bluesimcpp, $(tests)))
bluesimcpps: $(bluesimcpps)

$(bluesimcpps):
	make BOARD=bluesim --no-print-directory -C $(basename $@) bsim_exe

#################################################################################################
# xsim

xsimtests = $(addprefix examples/, $(addsuffix .xsim, $(examples))) \
	    $(addprefix tests/, $(addsuffix .xsim, $(tests)))
xsimtests: $(xsimtests)

$(xsimtests):
	rm -fr $(basename $@)/bluesim
	make BOARD=bluesim -C $(basename $@) xsim

xsimruns = $(addprefix examples/, $(addsuffix .xsimrun, $(examples))) \
	   $(addprefix tests/, $(addsuffix .xsimrun, $(tests)))
xsimruns: $(xsimruns)

$(xsimruns):
	make BOARD=bluesim -C $(basename $@) xsimrun

#################################################################################################
# zedboard

zedtests = $(addprefix examples/, $(addsuffix .zedboard, $(examples))) \
	   $(addprefix tests/, $(addsuffix .zedboard, $(tests)))
zedtests: $(zedtests)

$(zedtests):
	rm -fr $(basename $@)/zedboard
	make BOARD=zedboard -C $(basename $@) all

zedboardruns = $(addprefix examples/, $(addsuffix .zedboardrun, $(examples))) \
	       $(addprefix tests/, $(addsuffix .zedboardrun, $(tests)))
zedboardruns: $(zedboardruns)

# RUNPARAM=ipaddr is an optional argument if you already know the IP of the zedboard
$(zedboardruns):
	scripts/run.zedboard $(basename $@)/zedboard/bin/*bin.gz `find $(basename $@)/zedboard -name android_exe | grep libs`

zedboardcpps = $(addprefix examples/, $(addsuffix .zedboardcpp, $(examples))) \
	       $(addprefix tests/, $(addsuffix .zedboardcpp, $(tests)))
zedboardcpps: $(zedboardcpps)

# RUNPARAM=ipaddr is an optional argument if you already know the IP of the zedboard
$(zedboardcpps):
	make BOARD=zedboard --no-print-directory -C $(basename $@) exe

#################################################################################################
# zc702

zctests = $(addprefix examples/, $(addsuffix .zc702, $(examples))) \
	  $(addprefix tests/, $(addsuffix .zc702, $(tests)))
zctests: $(zctests)

$(zctests):
	rm -fr $(basename $@)/zc702
	make BOARD=zc702 -C $(basename $@) all

zc702runs = $(addprefix examples/, $(addsuffix .zc702run, $(examples))) \
	    $(addprefix tests/, $(addsuffix .zc702run, $(tests)))
zc702runs: $(zc702runs)

# RUNPARAM=ipaddr is an optional argument if you already know the IP of the zc702
$(zc702runs):
	scripts/run.zedboard $(basename $@)/zc702/bin/*bin.gz `find $(basename $@)/zc702 -name android_exe | grep libs`

#################################################################################################
# zc706

zc706tests = $(addprefix examples/, $(addsuffix .zc706, $(examples))) \
	     $(addprefix tests/, $(addsuffix .zc706, $(tests)))
zc706tests: $(zc706tests)

$(zc706tests):
	rm -fr $(basename $@)/zc706
	make BOARD=zc706 -C $(basename $@) all

zc706runs = $(addprefix examples/, $(addsuffix .zc706run, $(examples))) \
	    $(addprefix tests/, $(addsuffix .zc706run, $(tests)))
zc706runs: $(zc706runs)

# RUNPARAM=ipaddr is an optional argument if you already know the IP of the zc706
$(zc706runs):
	scripts/run.zedboard $(basename $@)/zc706/bin/*bin.gz `find $(basename $@)/zc706 -name android_exe | grep libs`

#################################################################################################
# vc707

vc707tests = $(addprefix examples/, $(addsuffix .vc707, $(examples))) \
	     $(addprefix tests/, $(addsuffix .vc707, $(tests)))
vc707tests: $9vc707tests)

$(vc707tests):
	rm -fr $(basename $@)/vc707
	make BOARD=vc707 -C $(basename $@) all

vc707runs = $(addprefix examples/, $(addsuffix .vc707run, $(examples))) \
	    $(addprefix tests/, $(addsuffix .vc707run, $(tests)))
vc707runs: $(vc707runs)

$(vc707runs):
	scripts/run.pcietest $(basename $@)/vc707/bin/mk*.bin.gz $(basename $@)/vc707/bin/mkpcietop

vc707cpps = $(addprefix examples/, $(addsuffix .vc707cpp, $(examples))) \
	    $(addprefix tests/, $(addsuffix .vc707cpp, $(tests)))
vc707cpps: $(vc707cpps)

$(vc707cpps):
	make BOARD=vc707 --no-print-directory -C $(basename $@) exe

#################################################################################################
# kc705

kc705tests = $(addprefix examples/, $(addsuffix .kc705, $(examples))) \
	     $(addprefix tests/, $(addsuffix .kc705, $(tests)))
kc705tests: $(kc705tests)

$(kc705tests):
	rm -fr $(basename $@)/kc705
	make BOARD=kc705 -C $(basename $@) all

kc705runs = $(addprefix examples/, $(addsuffix .kc705run, $(examples))) \
	    $(addprefix tests/, $(addsuffix .kc705run, $(tests)))
kc705runs: $(kc705runs)

$(kc705runs):
	scripts/run.pcietest $(basename $@)/kc705/bin/mk*.bin.gz $(basename $@)/kc705/bin/mkpcietop

kc705cpps = $(addprefix examples/, $(addsuffix .kc705cpp, $(examples))) \
	    $(addprefix tests/, $(addsuffix .kc705cpp, $(tests)))
kc705cpps: $(kc705cpps)

$(kc705cpps):
	make BOARD=kc705 --no-print-directory -C $(basename $@) exe


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

android_exetests = $(addprefix examples/, $(addsuffix .android_exe, $(examples)))
android_exetests: $(android_exetests)

$(android_exetests):
	make BOARD=zedboard -C $(basename $@) exe

ac701tests = $(addprefix examples/, $(addsuffix .ac701, $(examples)))
ac701tests: $(ac701tests)

$(ac701tests):
	rm -fr $(basename $@)/ac701
	make BOARD=ac701 -C $(basename $@) all

ac701runs = $(addprefix examples/, $(addsuffix .ac701run, $(examples)))
ac701runs: $(ac701runs)

$(ac701runs):
	scripts/run.pcietest $(basename $@)/ac701/bin/mk*.bin.gz $(basename $@)/ac701/bin/mkpcietop

zynqdrivers:
	(cd drivers/zynqportal/; DEVICE_XILINX_KERNEL=`pwd`/../../../linux-xlnx/ make zynqportal.ko)
	(cd drivers/portalmem/;  DEVICE_XILINX_KERNEL=`pwd`/../../../linux-xlnx/ make portalmem.ko)

zynqdrivers-clean:
	(cd drivers/zynqportal/; DEVICE_XILINX_KERNEL=`pwd`/../../../linux-xlnx/ make clean)
	(cd drivers/portalmem/;  DEVICE_XILINX_KERNEL=`pwd`/../../../linux-xlnx/ make clean)

zynqdrivers-install:
	cp drivers/zynqportal/zynqportal.ko drivers/portalmem/portalmem.ko ../zynq-boot/imagefiles/

#################################################################################################

xilinx/pcie_7x_gen1x8: scripts/generate-pcie-gen1x8.tcl
	rm -fr project_pcie_gen1x8
	vivado -mode batch -source scripts/generate-pcie-gen1x8.tcl
	mv ./project_pcie_gen1x8/project_pcie_gen1x8.srcs/sources_1/ip/pcie_7x_0 xilinx/pcie_7x_gen1x8
	rm -fr ./project_pcie_gen1x8

cppall:
	@for testname in $(cppalllist) ; do  \
	   for archname in $(allarchlist) ; do  \
	       echo make $$testname."$$archname"cpp;  \
	       make  --no-print-directory $$testname."$$archname"cpp;  \
	   done ;  \
	done

bsimall:
	@for testname in $(bsimalllist) ; do  \
	   echo make $$testname.bluesim;  \
	   make  --no-print-directory $$testname.bluesim >/dev/null;  \
	   echo make $$testname.bluesimrun;  \
	   make  --no-print-directory $$testname.bluesimrun;  \
	done

distclean:
	rm -rf examples/*/bluesim examples/*/vc707 examples/*/kc705 examples/*/zedboard examples/*/zc702 examples/*/zc706
	rm -rf tests/*/bluesim tests/*/vc707 tests/*/kc705 tests/*/zedboard tests/*/zc702 tests/*/zc706
	rm -rf drivers/*/.tmp_versions tests/memread_manual/kernel/.tmp_versions/
	rm -rf pcie/xbsvutil/xbsvutil tests/memread_manual/kernel/bsim_relay
	rm -rf out/

