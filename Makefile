
all:
	make parsetab.py
	(cd drivers/pcieportal; make)
	make -C pcie/xbsvutil

install:
	(cd drivers/pcieportal; make install)
	make -C pcie/xbsvutil install

uninstall:
	(cd drivers/pcieportal; make uninstall)
	make -C pcie/xbsvutil uninstall

docs:
	doxygen Doxyfile

install-dependences:
ifeq ($(shell uname), Darwin)
	port install asciidoc
	## PLY's home is http://www.dabeaz.com/ply/
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

matrixtests =testmm2.2.2         \
	    testmm2.2.4          \
	    testmm4.2.2          \
	    testmm4.4.2          \
	    testmm4.4.4          \
	    testmm8.8.2          \
	    testmm8.8.4          \
	    testmm16.16.2        

tests    =  $(memtests)          \
	    $(matrixtests)       \
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
	    testmm               \
            yuv                  

memexamples =  memcpy            \
            memread              \
	    memwrite             \
            memrw                \
	    memread2             

zmemexamples = memread_4m        \
            memwrite_4m          \
            $(memexamples)        

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
	make BOARD=bluesim -C $(basename $@) bsim_exe bsim


bluesimruns = $(addprefix examples/, $(addsuffix .bluesimrun, $(examples))) \
	      $(addprefix tests/, $(addsuffix .bluesimrun, $(tests)))
bluesimruns: $(bluesimruns)

$(bluesimruns):
	(cd $(basename $@)/bluesim; make run)

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
	scripts/run.zedboard `find $(basename $@)/zedboard -name \*.gz` `find $(basename $@)/zedboard -name android_exe | grep libs`


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
	scripts/run.zedboard `find $(basename $@)/zc702 -name \*.gz` `find $(basename $@)/zc702 -name android_exe | grep libs`

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
	scripts/run.zedboard `find $(basename $@)/zc706 -name \*.gz` `find $(basename $@)/zc706 -name android_exe | grep libs`

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
# misc

android_exetests = $(addprefix examples/, $(addsuffix .android_exe, $(examples)))
android_exetests: $(android_exetests)

$(android_exetests):
	make BOARD=zedboard -C $(basename $@) android_exe

ubuntu_exetests = $(addprefix examples/, $(addsuffix .ubuntu_exe, $(examples)))
ubuntu_exetests: $(ubuntu_exetests)

$(ubuntu_exetests):
	make BOARD=zedboard -C $(basename $@) ubuntu_exe

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
	(cd drivers/zynqportal/; DEVICE_XILINX_KERNEL=`pwd`/../../../device_xilinx_kernel/ make zynqportal.ko)
	(cd drivers/portalmem/;  DEVICE_XILINX_KERNEL=`pwd`/../../../device_xilinx_kernel/ make portalmem.ko)

#################################################################################################

xilinx/pcie_7x_gen1x8: scripts/generate-pcie-gen1x8.tcl
	rm -fr project_pcie_gen1x8
	vivado -mode batch -source scripts/generate-pcie-gen1x8.tcl
	mv ./project_pcie_gen1x8/project_pcie_gen1x8.srcs/sources_1/ip/pcie_7x_0 xilinx/pcie_7x_gen1x8
	rm -fr ./project_pcie_gen1x8

