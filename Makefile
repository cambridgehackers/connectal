
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
	    memwrite \
            mempoke  \
            strstr   \
            struct 


bsimtests = $(addsuffix .bsim, $(testnames))

$(bsimtests):
	pkill bluetcl || true
	rm -fr examples/$(basename $@)/bluesim
	make BOARD=bluesim -C examples/$(basename $@) bsim_exe bsim
	(cd examples/$(basename $@)/bluesim; ./sources/bsim& ./jni/bsim_exe)

bitstests = $(addsuffix .bits, $(testnames))

$(bitstests):
	rm -fr examples/$(basename $@)/zedboardnew
	make BOARD=zedboardnew -C examples/$(basename $@) all
	make -C examples/$(basename $@)/zedboardnew bits
	(cd examples/$(basename $@)/zedboardnew; ndk-build)

gentests = $(addsuffix .gen, $(testnames))

$(gentests):
	make BOARD=bluesim -C examples/$(basename $@) bsim_exe bsim


kc705tests = $(addsuffix .kc705, $(testnames))

$(kc705tests):
	rm -fr examples/$(basename $@)/kc705
	make BOARD=kc705 -C examples/$(basename $@) all

vc707tests = $(addsuffix .vc707, $(testnames))

$(vc707tests):
	rm -fr examples/$(basename $@)/vc707
	make BOARD=vc707 -C examples/$(basename $@) all


#################################################################################################
# not yet updated.

test-hdmi/hdmidisplay.bit.bin.gz: bsv/HdmiDisplay.bsv
	rm -fr test-hdmi
	./genxpsprojfrombsv -B $(BOARD) -p test-hdmi -x HDMI -b HdmiDisplay bsv/HdmiDisplay.bsv bsv/HDMI.bsv bsv/PortalMemory.bsv
	cd test-hdmi; make verilog && make bits && make hdmidisplay.bit.bin.gz
	echo test-hdmi built successfully

test-imageon/imagecapture.bit.bin.gz: examples/imageon/ImageCapture.bsv
	rm -fr test-imageon
	./genxpsprojfrombsv -B zc702 -p test-imageon -x ImageonVita -x HDMI -b ImageCapture --verilog=../imageon/sources/fmc_imageon_vita_receiver_v1_13_a examples/imageon/ImageCapture.bsv bsv/BlueScope.bsv bsv/AxiRDMA.bsv bsv/PortalMemory.bsv bsv/Imageon.bsv bsv/HDMI.bsv bsv/IserdesDatadeser.bsv
	cd test-imageon; make verilog && make bits && make imagecapture.bit.bin.gz
	echo test-imageon built successfully

xilinx/pcie_7x_v2_1: scripts/generate-pcie.tcl
	rm -fr proj_pcie
	vivado -mode batch -source scripts/generate-pcie.tcl
	mv ./proj_pcie/proj_pcie.srcs/sources_1/ip/pcie_7x_0 xilinx/pcie_7x_v2_1
	rm -fr ./proj_pcie

test-ring/sources/bsim: examples/ring/Ring.bsv examples/ring/testring.cpp
	-pkill bluetcl
	rm -fr test-ring
	./genxpsprojfrombsv -B $(BOARD) -p test-ring -b Ring examples/ring/Ring.bsv examples/ring/RingTypes.bsv bsv/BlueScope.bsv bsv/AxiSDMA.bsv bsv/PortalMemory.bsv -s examples/ring/testring.cpp
	cd test-ring; make x86_exe; cd ..
	cd test-ring; make bsim; cd ..
#	test-ring/sources/bsim &
#	test-ring/jni/ring
