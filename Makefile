
all: parsetab.py

docs:
	doxygen Doxyfile

BOARD=zedboard

parsetab.py: syntax.py
	python syntax.py

test: test-echo/ztop_1.bit.bin.gz test-memcpy/ztop_1.bit.bin.gz test-hdmi/hdmidisplay.bit.bin.gz


#################################################################################################
# examples/echo

gen_echo:
	./genxpsprojfrombsv -B$(BOARD) -p test-echo -x mkZynqTop -s2h Swallow -s2h EchoRequest -h2s EchoIndication -s examples/echo/testecho.cpp -t examples/echo/Top.bsv -V verilog examples/echo/Echo.bsv examples/echo/Swallow.bsv

test-echo/ztop_1.bit.bin.gz: examples/echo/Echo.bsv
	rm -fr test-echo
	make gen_echo
	cd test-echo; make verilog && make bits && make echo.bit.bin.gz
	cd test-echo; ndk-build

test-echo/sources/bsim: examples/echo/Top.bsv examples/echo/testecho.cpp
	-pkill bluetcl
	rm -fr test-echo
	make gen_echo
	cd test-echo; make bsim; cd ..
	cd test-echo; make bsim_exe; cd ..
	cd test-echo; sources/bsim& cd ..
	cd test-echo; jni/bsim_exe; cd ..

#################################################################################################
# examples/echo2

gen_echo2:
	./genxpsprojfrombsv -B $(BOARD) -p test-echo2 -x mkZynqTop -s2h Say -h2s Say -s examples/echo2/test.cpp -t examples/echo2/Top.bsv -V verilog examples/echo2/Say.bsv

test-echo2/sources/bsim: examples/echo2/Top.bsv examples/echo2/test.cpp
	-pkill bluetcl
	rm -fr test-echo2
	make gen_echo2
	cd test-echo2; make bsim; cd ..
	cd test-echo2; make bsim_exe; cd ..
	cd test-echo2; sources/bsim& cd ..
	cd test-echo2; jni/bsim_exe; cd ..

#################################################################################################
# examples/memcpy

gen_memcpy:
	./genxpsprojfrombsv -B $(BOARD) -p test-memcpy -x mkZynqTop -s2h MemcpyRequest -s2h BlueScopeRequest -s2h DMARequest -h2s MemcpyIndication -h2s BlueScopeIndication -h2s DMAIndication -s examples/memcpy/testmemcpy.cpp  -t examples/memcpy/Top.bsv -V verilog examples/memcpy/Memcpy.bsv bsv/BlueScope.bsv bsv/PortalMemory.bsv

test-memcpy/ztop_1.bit.bin.gz: examples/memcpy/Memcpy.bsv
	rm -fr test-memcpy
	make gen_memcpy
	cd test-memcpy; make verilog && make bits
	cd test-memcpy; ndk-build

test-memcpy/sources/bsim: examples/memcpy/Memcpy.bsv examples/memcpy/testmemcpy.cpp
	-pkill bluetcl
	rm -fr test-memcpy
	make gen_memcpy
	cd test-memcpy; make bsim; cd ..
	cd test-memcpy; make bsim_exe; cd ..
	cd test-memcpy; sources/bsim& cd ..
	cd test-memcpy; jni/bsim_exe; cd ..

#################################################################################################
# examples/loadstore

gen_loadstore:
	./genxpsprojfrombsv -B $(BOARD) -p test-loadstore -x mkZynqTop  -s2h LoadStoreRequest -s2h DMARequest -h2s LoadStoreIndication -h2s DMAIndication -s examples/loadstore/testloadstore.cpp -t examples/loadstore/Top.bsv -V verilog examples/loadstore/LoadStore.bsv bsv/PortalMemory.bsv

test-loadstore/loadstore.bit.bin.gz: examples/loadstore/LoadStore.bsv
	rm -fr test-loadstore
	make gen_loadstore
	cd test-loadstore; make verilog && make bits && make loadstore.bit.bin.gz
	cd test-loadstore; ndk-build
	echo test-loadstore built successfully

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

test-memread/sources/bsim: examples/memread/Memread.bsv examples/memread/testmemread.cpp
	-pkill bluetcl
	rm -fr test-memread
	./genxpsprojfrombsv -B $(BOARD) -p test-memread -b Memread examples/memread/Memread.bsv bsv/BlueScope.bsv bsv/AxiRDMA.bsv bsv/PortalMemory.bsv -s examples/memread/testmemread.cpp
	cd test-memread; make x86_exe; cd ..
	cd test-memread; make bsim; cd ..
	test-memread/sources/bsim &
	test-memread/jni/memread

test-memwrite/sources/bsim: examples/memwrite/Memwrite.bsv examples/memwrite/testmemwrite.cpp
	-pkill bluetcl
	rm -fr test-memwrite
	./genxpsprojfrombsv -B $(BOARD) -p test-memwrite -b Memwrite examples/memwrite/Memwrite.bsv bsv/BlueScope.bsv bsv/AxiRDMA.bsv bsv/PortalMemory.bsv -s examples/memwrite/testmemwrite.cpp
	cd test-memwrite; make x86_exe; cd ..
	cd test-memwrite; make bsim; cd ..
	test-memwrite/sources/bsim &
	test-memwrite/jni/memwrite

test-struct/sources/bsim: examples/struct/Struct.bsv examples/struct/teststruct.cpp
	-pkill bluetcl
	rm -fr test-struct
	./genxpsprojfrombsv -B $(BOARD) -p test-struct -b Struct examples/struct/Struct.bsv bsv/BlueScope.bsv bsv/AxiRDMA.bsv bsv/PortalMemory.bsv -s examples/struct/teststruct.cpp
	cd test-struct; make x86_exe; cd ..
	cd test-struct; make bsim; cd ..
	test-struct/sources/bsim &
	test-struct/jni/struct



test-strstr/sources/bsim: examples/strstr/Strstr.bsv examples/strstr/teststrstr.cpp
	-pkill bluetcl
	rm -fr test-strstr
	./genxpsprojfrombsv -B $(BOARD) -p test-strstr -b Strstr examples/strstr/Strstr.bsv bsv/BlueScope.bsv bsv/AxiRDMA.bsv bsv/PortalMemory.bsv -s examples/strstr/teststrstr.cpp
	cd test-strstr; make x86_exe; cd ..
	cd test-strstr; make bsim; cd ..
	test-strstr/sources/bsim &
	test-strstr/jni/strstr


clean_sockets:
	rm -rf fpga*
	rm -rf fd_*

xilinx/pcie_7x_v2_1: scripts/generate-pcie.tcl
	rm -fr proj_pcie
	vivado -mode batch -source scripts/generate-pcie.tcl
	mv ./proj_pcie/proj_pcie.srcs/sources_1/ip/pcie_7x_0 xilinx/pcie_7x_v2_1
	rm -fr ./proj_pcie

k7echoproj:
	./genxpsprojfrombsv -B kc705 -p k7echoproj -s examples/echo/testecho.cpp -b Echo examples/echo/Echo.bsv && (cd k7echoproj && time make implementation)

v7echoproj:
	./genxpsprojfrombsv -B vc707 -p v7echoproj -s examples/echo/testecho.cpp -b Echo examples/echo/Echo.bsv && (cd v7echoproj && time make implementation)

test-mempoke/sources/bsim: examples/mempoke/Mempoke.bsv examples/mempoke/testmempoke.cpp
	-pkill bluetcl
	rm -fr test-mempoke
	./genxpsprojfrombsv -B $(BOARD) -p test-mempoke -b Mempoke examples/mempoke/Mempoke.bsv bsv/BlueScope.bsv bsv/AxiRDMA.bsv bsv/PortalMemory.bsv -s examples/mempoke/testmempoke.cpp
	cd test-mempoke; make x86_exe; cd ..
	cd test-mempoke; make bsim; cd ..
	test-mempoke/sources/bsim &
	test-mempoke/jni/mempoke

test-ring/sources/bsim: examples/ring/Ring.bsv examples/ring/testring.cpp
	-pkill bluetcl
	rm -fr test-ring
	./genxpsprojfrombsv -B $(BOARD) -p test-ring -b Ring examples/ring/Ring.bsv examples/ring/RingTypes.bsv bsv/BlueScope.bsv bsv/AxiSDMA.bsv bsv/PortalMemory.bsv -s examples/ring/testring.cpp
	cd test-ring; make x86_exe; cd ..
	cd test-ring; make bsim; cd ..
#	test-ring/sources/bsim &
#	test-ring/jni/ring
