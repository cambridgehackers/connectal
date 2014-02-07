
all: parsetab.py

docs:
	doxygen Doxyfile

BOARD=zedboard

parsetab.py: syntax.py
	python syntax.py

test: test-echo/ztop_1.bit.bin.gz test-memcpy/ztop_1.bit.bin.gz test-hdmi/hdmidisplay.bit.bin.gz


#################################################################################################
# Generate bsim and zynq make targets for each test in testnames.
# For test 'foo', we will generate 'foo.bits' and 'foo.bsim'

testnames = echo     \
            echo2    \
            memcpy   \
            memread  \
            memread2 \
	    memwrite \
            mempoke  \
            strstr   \
            struct   \
	    ring     \
	    nandsim  \
            flowcontrol

bsimtests = $(addsuffix .bsim, $(testnames))

$(bsimtests):
	rm -fr examples/$(basename $@)/bluesim
	make BOARD=bluesim -C examples/$(basename $@) bsim_exe bsim
	(cd examples/$(basename $@)/bluesim; ./sources/bsim& bsimpid=$$!; echo bsimpid $$bsimpid; ./jni/bsim_exe; retcode=$$?; kill $$bsimpid; exit $$retcode)

zedtests = $(addsuffix .zedboard, $(testnames))

$(zedtests):
	rm -fr examples/$(basename $@)/zedboard
	make BOARD=zedboard -C examples/$(basename $@) all

zedruns = $(addsuffix .zedrun, $(testnames))

# RUNPARAM=ipaddr is an optional argument if you already know the IP of the zedboard
$(zedruns):
	(cd consolable; make)
	scripts/run.zedboard $(RUNPARAM) `find examples/$(basename $@)/zedboard -name \*.gz` `find examples/$(basename $@)/zedboard -name android_exe | grep libs`

zctests = $(addsuffix .zc702, $(testnames))

$(zctests):
	rm -fr examples/$(basename $@)/zc702
	make BOARD=zc702 -C examples/$(basename $@) all

zcruns = $(addsuffix .zcrun, $(testnames))

# RUNPARAM=ipaddr is an optional argument if you already know the IP of the zc702
$(zcruns):
	(cd consolable; make)
	scripts/run.zedboard $(RUNPARAM) `find examples/$(basename $@)/zc702 -name \*.gz` `find examples/$(basename $@)/zc702 -name android_exe | grep libs`

bsim_exetests = $(addsuffix .bsim_exe, $(testnames))

$(bsim_exetests):
	make BOARD=bluesim -C examples/$(basename $@) bsim_exe
	(cd examples/$(basename $@)/bluesim; ./sources/bsim& bsimpid=$$!; echo bsimpid $$bsimpid; ./jni/bsim_exe; retcode=$$?; kill $$bsimpid; exit $$retcode)

android_exetests = $(addsuffix .android_exe, $(testnames))

$(android_exetests):
	make BOARD=zedboard -C examples/$(basename $@) android_exe

kc705tests = $(addsuffix .kc705, $(testnames))

$(kc705tests):
	rm -fr examples/$(basename $@)/kc705
	make BOARD=kc705 -C examples/$(basename $@) all

kcruns = $(addsuffix .kcrun, $(testnames))

$(kcruns):
	(cd examples/$(basename $@)/kc705; make program)
	scripts/pciescan.sh
	catchsegv examples/$(basename $@)/kc707/jni/mkpcietop

vc707tests = $(addsuffix .vc707, $(testnames))

$(vc707tests):
	rm -fr examples/$(basename $@)/vc707
	make BOARD=vc707 -C examples/$(basename $@) all

vcruns = $(addsuffix .vcrun, $(testnames))

$(vcruns):
	(cd examples/$(basename $@)/vc707; make program)
	scripts/pciescan.sh
	catchsegv examples/$(basename $@)/vc707/jni/mkpcietop

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

