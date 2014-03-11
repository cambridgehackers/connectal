
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

testnames = echo             \
            echo2            \
            memcpy_buff      \
            memcpy_nobuff    \
            memread_buff     \
            memread_nobuff   \
	    memwrite_buff    \
	    memwrite_nobuff  \
            memrw_buff       \
            memrw_nobuff     \
            memread128       \
            memread2         \
            mempoke          \
            strstr           \
            struct           \
	    ring             \
	    perf             \
	    nandsim          \
            flowcontrol      \
            bluescope        \
            bscan            \



memtests =  memcpy_buff      \
            memcpy_nobuff    \
            memread_buff     \
            memread_nobuff   \
	    memwrite_buff    \
	    memwrite_nobuff  \
            memrw_buff       \
            memrw_nobuff     \
	    echo

memtests.zedboard: $(addsuffix .zedboard, $(memtests))

memtests.zedrun:  $(addsuffix .zedrun, $(memtests))

memtests.zedboard.regression:
	make -j 10 LM_LICENSE_FILE=1709@chastity.csail.mit.edu memtests.zedboard

memtests.kc705: $(addsuffix .kc705, $(memtests))

memtests.kcrun:  $(addsuffix .kcrun, $(memtests))

memtests.kc705.regression:
	make -j 10 LM_LICENSE_FILE=1709@chastity.csail.mit.edu memtests.kc705



bsimtests = $(addsuffix .bsim, $(testnames))

bsimtests: $(bsimtests)

$(bsimtests):
	rm -fr examples/$(basename $@)/bluesim
	make BOARD=bluesim -C examples/$(basename $@) bsim_exe bsim
	(cd examples/$(basename $@)/bluesim; ./sources/bsim& bsimpid=$$!; echo bsimpid $$bsimpid; ./jni/bsim_exe; retcode=$$?; kill $$bsimpid; exit $$retcode)

bsimruns = $(addsuffix .bsimrun, $(testnames))

bsimruns: $(bsimruns)

$(bsimruns):
	# already executed test in 'bsim'

zedtests = $(addsuffix .zedboard, $(testnames))

zedtests: $(zedtests)

$(zedtests):
	rm -fr examples/$(basename $@)/zedboard
	make BOARD=zedboard -C examples/$(basename $@) all

zedruns = $(addsuffix .zedrun, $(testnames))

zedruns: $(zedruns)

# RUNPARAM=ipaddr is an optional argument if you already know the IP of the zedboard
$(zedruns):
	(cd consolable; make)
	scripts/run.zedboard $(RUNPARAM) `find examples/$(basename $@)/zedboard -name \*.gz` `find examples/$(basename $@)/zedboard -name android_exe | grep libs`

zedboardruns = $(addsuffix .zedboardrun, $(testnames))

zedboardruns: $(zedboardruns)

# RUNPARAM=ipaddr is an optional argument if you already know the IP of the zedboard
$(zedboardruns):
	(cd consolable; make)
	scripts/run.zedboard $(RUNPARAM) `find examples/$(basename $@)/zedboard -name \*.gz` `find examples/$(basename $@)/zedboard -name android_exe | grep libs`

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
	scripts/run.zedboard $(RUNPARAM) `find examples/$(basename $@)/zc702 -name \*.gz` `find examples/$(basename $@)/zc702 -name android_exe | grep libs`

bsim_exetests = $(addsuffix .bsim_exe, $(testnames))

bsim_exetests: $(bsim_exetests)

$(bsim_exetests):
	make BOARD=bluesim -C examples/$(basename $@) bsim_exe
	(cd examples/$(basename $@)/bluesim; ./sources/bsim& bsimpid=$$!; echo bsimpid $$bsimpid; ./jni/bsim_exe; retcode=$$?; kill $$bsimpid; exit $$retcode)

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
	catchsegv examples/$(basename $@)/ac701/jni/mkpcietop

kc705tests = $(addsuffix .kc705, $(testnames))
kc705tests: $(kc705tests)

$(kc705tests):
	rm -fr examples/$(basename $@)/kc705
	make BOARD=kc705 -C examples/$(basename $@) all

kcruns = $(addsuffix .kcrun, $(testnames))
kcruns: $(kcruns)

$(kcruns):
	(cd examples/$(basename $@)/kc705; make program)
	pciescanportal
	catchsegv examples/$(basename $@)/kc705/jni/mkpcietop

kc705runs = $(addsuffix .kc705run, $(testnames))
kc705runs: $(kc705runs)

$(kc705runs):
	(cd examples/$(basename $@)/kc705; make program)
	pciescanportal
	catchsegv examples/$(basename $@)/kc705/jni/mkpcietop

vc707tests = $(addsuffix .vc707, $(testnames))
vc707tests: $9vc707tests)

$(vc707tests):
	rm -fr examples/$(basename $@)/vc707
	make BOARD=vc707 -C examples/$(basename $@) all

vcruns = $(addsuffix .vcrun, $(testnames))
vcruns: $(vcruns)

$(vcruns):
	(cd examples/$(basename $@)/vc707; make program)
	pciescanportal
	catchsegv examples/$(basename $@)/vc707/jni/mkpcietop

vc707runs = $(addsuffix .vc707run, $(testnames))
vc707runs: $(vc707runs)

$(vc707runs):
	(cd examples/$(basename $@)/vc707; make program)
	pciescanportal
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

