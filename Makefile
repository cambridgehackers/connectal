
all:
	make parsetab.py
	(cd drivers/pcieportal; make)
	make -C pcie/xbsvutil
	make -C consolable

install:
	(cd drivers/pcieportal; make install)
	make -C pcie/xbsvutil install
	make -C util install

uninstall:
	(cd drivers/pcieportal; make uninstall)
	make -C pcie/xbsvutil uninstall
	make -C util uninstall

docs:
	doxygen Doxyfile

BOARD=zedboard

parsetab.py: syntax.py
	python syntax.py

test: test-echo/ztop_1.bit.bin.gz test-memcpy/ztop_1.bit.bin.gz test-hdmi/hdmidisplay.bit.bin.gz

#################################################################################################
# Generate bsim and zynq make targets for each test in testnames.
# For test 'foo', we will generate 'foo.bits' and 'foo.bsim'

testnames = echo             \
	    hdmidisplay      \
	    imageon          \
            memcpy_buff      \
            memcpy_buff_oo   \
            memcpy_nobuff    \
            memread_buff_oo  \
            memread_buff     \
            memread_nobuff   \
	    memwrite_buff    \
	    memwrite_buff_oo \
	    memwrite_nobuff  \
            memrw_buff       \
            memrw_nobuff     \
            memread128       \
            memread2         \
            mempoke          \
            pcietestbench    \
            pcietestbench_dma_io  \
            pcietestbench_dma_oo  \
            simple           \
            strstr           \
	    ring             \
	    perf             \
	    nandsim          \
            flowcontrol      \
            bluescope        \
            bscan            \
	    splice           \
	    maxcommonsubseq  \
	    fib              \
	    xsim-echo        \

oo_memtests =  memcpy_buff_oo   \
            memread_buff_oo  \
            memwrite_buff_oo \


memtests =  memcpy_buff      \
            memcpy_nobuff    \
            memread_buff     \
            memread_nobuff   \
	    memwrite_buff    \
	    memwrite_nobuff  \
            memrw_buff       \
            memrw_nobuff     \
            echo             \


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
	(cd consolable; make)
	(cd timelimit; ndk-build)
	scripts/run.zedboard $(RUNPARAM) `find examples/$(basename $@)/zedboard -name \*.gz` `find examples/$(basename $@)/zedboard -name android_exe | grep libs`


#################################################################################################
# zc702

zctests = $(addsuffix .zc702, $(testnames))
zctests: $(zctests)

$(zctests):
	rm -fr examples/$(basename $@)/zc702
	make BOARD=zc702 -C examples/$(basename $@) all

zcruns = $(addsuffix .zcrun, $(testnames))
zcruns: $(zcruns)

# RUNPARAM=ipaddr is an optional argument if you already know the IP of the zc702
$(zcruns):
	(cd consolable; make)
	(cd timelimit; ndk-build)
	scripts/run.zedboard $(RUNPARAM) `find examples/$(basename $@)/zc702 -name \*.gz` `find examples/$(basename $@)/zc702 -name android_exe | grep libs`

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
	(cd consolable; make)
	(cd timelimit; ndk-build)
	scripts/run.zedboard $(RUNPARAM) `find examples/$(basename $@)/zc706 -name \*.gz` `find examples/$(basename $@)/zc706 -name android_exe | grep libs`

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
	(cd examples/$(basename $@)/vc707; make program)
	pciescanportal
	timeout 3m catchsegv examples/$(basename $@)/vc707/jni/mkpcietop

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
	(cd examples/$(basename $@)/kc705; make program)
	pciescanportal
	timeout 3m catchsegv examples/$(basename $@)/kc705/jni/mkpcietop


#################################################################################################
# memtests

memtests.zedboard: $(addsuffix .zedboard, $(memtests))
memtests.zedboard.regression:
	make -j 10 LM_LICENSE_FILE=1709@chastity.csail.mit.edu memtests.zedboard

memtests.kc705: $(addsuffix .kc705, $(memtests))
memtests.kc705.regression:
	make -j 6 LM_LICENSE_FILE=1709@chastity.csail.mit.edu memtests.kc705

memtests.bsim: $(addsuffix .bsim, $(memtests))
memtests.bsim.regression:
	make -j 10 LM_LICENSE_FILE=1709@chastity.csail.mit.edu memtests.bsim
memtests.bsimrun: $(addsuffix .bsimrun, $(memtests))
memtests.bsimrun.regression:
	make LM_LICENSE_FILE=1709@chastity.csail.mit.edu memtests.bsimrun

#################################################################################################
# oo_memtests

oo_memtests.zedboard: $(addsuffix .zedboard, $(oo_memtests))
oo_memtests.zedboard.regression:
	make -j 10 LM_LICENSE_FILE=1709@chastity.csail.mit.edu oo_memtests.zedboard

oo_memtests.kc705: $(addsuffix .kc705, $(oo_memtests))
oo_memtests.kc705.regression:
	make -j 6 LM_LICENSE_FILE=1709@chastity.csail.mit.edu oo_memtests.kc705

oo_memtests.bsim: $(addsuffix .bsim, $(oo_memtests))
oo_memtests.bsim.regression:
	make -j 10 LM_LICENSE_FILE=1709@chastity.csail.mit.edu oo_memtests.bsim
oo_memtests.bsimrun: $(addsuffix .bsimrun, $(oo_memtests))
oo_memtests.bsimrun.regression:
	make LM_LICENSE_FILE=1709@chastity.csail.mit.edu oo_memtests.bsimrun

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

acruns = $(addsuffix .acrun, $(testnames))
acruns: $(acruns)

$(acruns):
	(cd examples/$(basename $@)/ac701; make program)
	pciescanportal
	timeout 3m catchsegv examples/$(basename $@)/ac701/jni/mkpcietop

zynqdrivers:
	(cd drivers/zynqportal/; DEVICE_XILINX_KERNEL=`pwd`/../../../device_xilinx_kernel/ make zynqportal.ko)
	(cd drivers/portalmem/;  DEVICE_XILINX_KERNEL=`pwd`/../../../device_xilinx_kernel/ make portalmem.ko)

#################################################################################################
# not yet updated.

test-hdmi/hdmidisplay.bit.bin.gz: bsv/HdmiDisplay.bsv
	rm -fr test-hdmi
	./genxpsprojfrombsv -B $(BOARD) -p test-hdmi -x HDMI -b HdmiDisplay bsv/HdmiDisplay.bsv bsv/HDMI.bsv bsv/PortalMemory.bsv
	cd test-hdmi; make verilog && make bits && make hdmidisplay.bit.bin.gz
	echo test-hdmi built successfully

test-imageon/imagecapture.bit.bin.gz: examples/imageon/ImageCapture.bsv
	rm -fr test-imageon
	./genxpsprojfrombsv -B zc702 -p test-imageon -x ImageonVita -x HDMI -b ImageCapture --verilog=../imageon/sources/fmc_imageon_vita_receiver_v1_13_a examples/imageon/ImageCapture.bsv bsv/BlueScope.bsv bsv/AxiDma.bsv bsv/PortalMemory.bsv bsv/Imageon.bsv bsv/HDMI.bsv bsv/IserdesDatadeser.bsv
	cd test-imageon; make verilog && make bits && make imagecapture.bit.bin.gz
	echo test-imageon built successfully

xilinx/pcie_7x_v2_1: scripts/generate-pcie.tcl
	rm -fr proj_pcie
	vivado -mode batch -source scripts/generate-pcie.tcl
	mv ./proj_pcie/proj_pcie.srcs/sources_1/ip/pcie_7x_0 xilinx/pcie_7x_v2_1
	rm -fr ./proj_pcie

