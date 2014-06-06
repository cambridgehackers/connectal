
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

test: test-echo/ztop_1.bit.bin.gz test-memcpy/ztop_1.bit.bin.gz test-hdmi/hdmidisplay.bit.bin.gz

#################################################################################################
# Generate bsim and zynq make targets for each test in testnames.
# For test 'foo', we will generate 'foo.bits' and 'foo.bsim'

testnames = echo             \
	    hdmidisplay      \
            memcpy_buff      \
            memcpy_buff_oo   \
            memcpy_nobuff    \
            memread_buff_oo  \
            memread_buff     \
            memread_nobuff   \
            memread_manyclients \
	    memwrite_buff    \
	    memwrite_buff_oo \
	    memwrite_nobuff  \
            memwrite_manyclients \
            memrw_buff       \
            memrw_nobuff     \
            memread128       \
            memread2         \
            mempoke          \
            pcietestbench    \
            pcietestbench_dma_io  \
            pcietestbench_dma_oo  \
            pipe_mul         \
            pipe_mul2        \
            printf           \
            simple           \
            strstr           \
	    ring             \
	    perf             \
	    nandsim          \
            flowcontrol      \
            bluescope        \
	    splice           \
	    maxcommonsubseq  \
	    smithwaterman    \
	    serialconfig     \
	    noc              \
	    noc2d            \
	    fib              \
	    xsim-echo        \
	    imageon          \
	    imageonfb        \
            bscan            \
            memread_nobuff_4m    \
            memwrite_nobuff_4m   \
            memcpy_buff_4m       \

oo_memtests =  memcpy_buff_oo\
            memread_buff_oo  \
            memwrite_buff_oo \


memtests =  memcpy_buff          \
            memcpy_nobuff        \
            memread_buff         \
            memread_nobuff       \
	    memwrite_buff        \
	    memwrite_nobuff      \
            memrw_buff           \
            memrw_nobuff         \
	    memread2             \
            echo                 \
            memread_manyclients  \
            memwrite_manyclients \



zmemtests = memread_nobuff_4m\
            memwrite_nobuff_4m\
            memcpy_buff_4m\
            memtests


#################################################################################################
# gdb

%.gdb:
	make XBSV_DEBUG=1 $*

#################################################################################################
# bsim

bsimtests = $(addsuffix .bsim, $(testnames))
bsimtests: $(bsimtests)

$(bsimtests):
	rm -fr examples/$(basename $@)/bluesim
	make BOARD=bluesim -C examples/$(basename $@) bsim_exe bsim


bsimruns = $(addsuffix .bsimrun, $(testnames))
bsimruns: $(bsimruns)

$(bsimruns):
	(cd examples/$(basename $@)/bluesim; make run)

#################################################################################################
# xsim

xsimtests = $(addsuffix .xsim, $(testnames))
xsimtests: $(xsimtests)

$(xsimtests):
	rm -fr examples/$(basename $@)/bluesim
	make BOARD=bluesim -C examples/$(basename $@) xsim

xsimruns = $(addsuffix .xsimrun, $(testnames))
xsimruns: $(xsimruns)

$(xsimruns):
	make BOARD=bluesim -C examples/$(basename $@) xsimrun

#################################################################################################
# zedboard

zedtests = $(addsuffix .zedboard, $(testnames))
zedtests: $(zedtests)

$(zedtests):
	rm -fr examples/$(basename $@)/zedboard
	make BOARD=zedboard -C examples/$(basename $@) all

zedboardruns = $(addsuffix .zedboardrun, $(testnames))
zedboardruns: $(zedboardruns)

# RUNPARAM=ipaddr is an optional argument if you already know the IP of the zedboard
$(zedboardruns):
	scripts/run.zedboard `find examples/$(basename $@)/zedboard -name \*.gz` `find examples/$(basename $@)/zedboard -name android_exe | grep libs`


#################################################################################################
# zc702

zctests = $(addsuffix .zc702, $(testnames))
zctests: $(zctests)

$(zctests):
	rm -fr examples/$(basename $@)/zc702
	make BOARD=zc702 -C examples/$(basename $@) all

zc702runs = $(addsuffix .zc702run, $(testnames))
zc702runs: $(zc702runs)

# RUNPARAM=ipaddr is an optional argument if you already know the IP of the zc702
$(zc702runs):
	scripts/run.zedboard `find examples/$(basename $@)/zc702 -name \*.gz` `find examples/$(basename $@)/zc702 -name android_exe | grep libs`

#################################################################################################
# zc706

zc706tests = $(addsuffix .zc706, $(testnames))
zc706tests: $(zc706tests)

$(zc706tests):
	rm -fr examples/$(basename $@)/zc706
	make BOARD=zc706 -C examples/$(basename $@) all

zc706runs = $(addsuffix .zc706run, $(testnames))
zc706runs: $(zc706runs)

# RUNPARAM=ipaddr is an optional argument if you already know the IP of the zc706
$(zc706runs):
	scripts/run.zedboard `find examples/$(basename $@)/zc706 -name \*.gz` `find examples/$(basename $@)/zc706 -name android_exe | grep libs`

#################################################################################################
# vc707

vc707tests = $(addsuffix .vc707, $(testnames))
vc707tests: $9vc707tests)

$(vc707tests):
	rm -fr examples/$(basename $@)/vc707
	make BOARD=vc707 -C examples/$(basename $@) all

vc707runs = $(addsuffix .vc707run, $(testnames))
vc707runs: $(vc707runs)

$(vc707runs):
	scripts/run.pcietest examples/$(basename $@)/vc707/bin/mk*.bin.gz examples/$(basename $@)/vc707/bin/mkpcietop

#################################################################################################
# kc705

kc705tests = $(addsuffix .kc705, $(testnames))
kc705tests: $(kc705tests)

$(kc705tests):
	rm -fr examples/$(basename $@)/kc705
	make BOARD=kc705 -C examples/$(basename $@) all

kc705runs = $(addsuffix .kc705run, $(testnames))
kc705runs: $(kc705runs)

$(kc705runs):
	scripts/run.pcietest examples/$(basename $@)/kc705/bin/mk*.bin.gz examples/$(basename $@)/kc705/bin/mkpcietop


#################################################################################################
# memtests

memtests.zedboard: $(addsuffix .zedboard, $(memtests))

memtests.kc705: $(addsuffix .kc705, $(memtests))

memtests.bsim: $(addsuffix .bsim, $(memtests))

memtests.bsimrun: $(addsuffix .bsimrun, $(memtests))

#################################################################################################
# zmemtests

zmemtests.zedboard: $(addsuffix .zedboard, $(zmemtests))

zmemtests.bsim: $(addsuffix .bsim, $(zmemtests))

zmemtests.bsimrun: $(addsuffix .bsimrun, $(zmemtests))

#################################################################################################
# oo_memtests

oo_memtests.zedboard: $(addsuffix .zedboard, $(oo_memtests))

oo_memtests.kc705: $(addsuffix .kc705, $(oo_memtests))

oo_memtests.bsim: $(addsuffix .bsim, $(oo_memtests))

oo_memtests.bsimrun: $(addsuffix .bsimrun, $(oo_memtests))

#################################################################################################
# misc

android_exetests = $(addsuffix .android_exe, $(testnames))
android_exetests: $(android_exetests)

$(android_exetests):
	make BOARD=zedboard -C examples/$(basename $@) android_exe

ubuntu_exetests = $(addsuffix .ubuntu_exe, $(testnames))
ubuntu_exetests: $(ubuntu_exetests)

$(ubuntu_exetests):
	make BOARD=zedboard -C examples/$(basename $@) ubuntu_exe

ac701tests = $(addsuffix .ac701, $(testnames))
ac701tests: $(ac701tests)

$(ac701tests):
	rm -fr examples/$(basename $@)/ac701
	make BOARD=ac701 -C examples/$(basename $@) all

ac701runs = $(addsuffix .ac701run, $(testnames))
ac701runs: $(ac701runs)

$(ac701runs):
	scripts/run.pcietest examples/$(basename $@)/ac701/bin/mk*.bin.gz examples/$(basename $@)/ac701/bin/mkpcietop

zynqdrivers:
	(cd drivers/zynqportal/; DEVICE_XILINX_KERNEL=`pwd`/../../../device_xilinx_kernel/ make zynqportal.ko)
	(cd drivers/portalmem/;  DEVICE_XILINX_KERNEL=`pwd`/../../../device_xilinx_kernel/ make portalmem.ko)

#################################################################################################

xilinx/pcie_7x_gen1x8: scripts/generate-pcie-gen1x8.tcl
	rm -fr project_pcie_gen1x8
	vivado -mode batch -source scripts/generate-pcie-gen1x8.tcl
	mv ./project_pcie_gen1x8/project_pcie_gen1x8.srcs/sources_1/ip/pcie_7x_0 xilinx/pcie_7x_gen1x8
	rm -fr ./project_pcie_gen1x8

