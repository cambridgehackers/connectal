
all: parsetab.py

BOARD=zedboard

parsetab.py: syntax.py
	python syntax.py

test: test-echo/echo.bit.bin.gz test-memcpy/memcpy.bit.bin.gz test-hdmi/hdmidisplay.bit.bin.gz

test-echo/echo.bit.bin.gz: examples/echo/Echo.bsv
	rm -fr test-echo
	mkdir test-echo
	./genxpsprojfrombsv -B $(BOARD) -p test-echo -b Echo examples/echo/Echo.bsv
	cd test-echo; make verilog && make bits && make echo.bit.bin.gz
	cp examples/echo/testecho.cpp test-echo/jni
	(cd test-echo; ndk-build)
	echo test-echo built successfully

test-memcpy/memcpy.bit.bin.gz: examples/memcpy/Memcpy.bsv
	rm -fr test-memcpy
	mkdir test-memcpy
	./genxpsprojfrombsv -B $(BOARD) -p test-memcpy -b Memcpy examples/memcpy/Memcpy.bsv bsv/BlueScope.bsv bsv/AxiSDMA.bsv bsv/PortalMemory.bsv
	cd test-memcpy; make verilog && make bits && make memcpy.bit.bin.gz
	cp examples/memcpy/testmemcpy.cpp test-memcpy/jni
	(cd test-memcpy; ndk-build)
	echo test-memcpy built successfully

test-loadstore/loadstore.bit.bin.gz: examples/loadstore/LoadStore.bsv
	rm -fr test-loadstore
	mkdir test-loadstore
	./genxpsprojfrombsv -B $(BOARD) -p test-loadstore -b LoadStore examples/loadstore/LoadStore.bsv
	cd test-loadstore; make verilog && make bits && make loadstore.bit.bin.gz
	cp examples/loadstore/testloadstore.cpp test-loadstore/jni
	(cd test-loadstore; ndk-build)
	echo test-loadstore built successfully

test-hdmi/hdmidisplay.bit.bin.gz: bsv/HdmiDisplay.bsv
	rm -fr test-hdmi
	mkdir test-hdmi
	./genxpsprojfrombsv -B $(BOARD) -p test-hdmi -b HdmiDisplay bsv/HdmiDisplay.bsv
	cd test-hdmi; make verilog && make bits && make hdmidisplay.bit.bin.gz
	echo test-hdmi built successfully

test-imageon/imagecapture.bit.bin.gz: examples/imageon/ImageCapture.bsv
	rm -fr test-imageon
	mkdir test-imageon
	./genxpsprojfrombsv -B zc702 -p test-imageon -b ImageCapture --verilog=../imageon/sources/fmc_imageon_vita_receiver_v1_13_a examples/imageon/ImageCapture.bsv bsv/BlueScope.bsv bsv/AxiSDMA.bsv bsv/PortalMemory.bsv
	cd test-imageon; make verilog && make bits && make imagecapture.bit.bin.gz
	echo test-imageon built successfully

test-memcpy/sources/bsim: examples/memcpy/Memcpy.bsv examples/memcpy/testmemcpy.cpp
	-pkill bluetcl
	rm -fr test-memcpy
	mkdir test-memcpy
	./genxpsprojfrombsv -B $(BOARD) -p test-memcpy -b Memcpy examples/memcpy/Memcpy.bsv bsv/BlueScope.bsv bsv/AxiSDMA.bsv bsv/PortalMemory.bsv -s  examples/memcpy/testmemcpy.cpp
	cd test-memcpy; make bsim; cd ..
	cd test-memcpy; make x86_exe; cd ..
	test-memcpy/sources/bsim &
	test-memcpy/jni/memcpy


test-memread/sources/bsim: examples/memread/Memread.bsv examples/memread/testmemread.cpp
	-pkill bluetcl
	rm -fr test-memread
	mkdir test-memread
	./genxpsprojfrombsv -B $(BOARD) -p test-memread -b Memread examples/memread/Memread.bsv bsv/BlueScope.bsv bsv/AxiSDMA.bsv bsv/PortalMemory.bsv -s examples/memread/testmemread.cpp
	cd test-memread; make x86_exe; cd ..
	cd test-memread; make bsim; cd ..
	test-memread/sources/bsim &
	test-memread/jni/memread

test-memwrite/sources/bsim: examples/memwrite/Memwrite.bsv examples/memwrite/testmemwrite.cpp
	-pkill bluetcl
	rm -fr test-memwrite
	mkdir test-memwrite
	./genxpsprojfrombsv -B $(BOARD) -p test-memwrite -b Memwrite examples/memwrite/Memwrite.bsv bsv/BlueScope.bsv bsv/AxiSDMA.bsv bsv/PortalMemory.bsv -s examples/memwrite/testmemwrite.cpp
	cd test-memwrite; make x86_exe; cd ..
	cd test-memwrite; make bsim; cd ..
	test-memwrite/sources/bsim &
	test-memwrite/jni/memwrite

test-struct/sources/bsim: examples/struct/Struct.bsv examples/struct/teststruct.cpp
	-pkill bluetcl
	rm -fr test-struct
	mkdir test-struct
	./genxpsprojfrombsv -B $(BOARD) -p test-struct -b Struct examples/struct/Struct.bsv bsv/BlueScope.bsv bsv/AxiSDMA.bsv bsv/PortalMemory.bsv -s examples/struct/teststruct.cpp
	cd test-struct; make x86_exe; cd ..
	cd test-struct; make bsim; cd ..
	test-struct/sources/bsim &
	test-struct/jni/struct



test-strstr/sources/bsim: examples/strstr/Strstr.bsv examples/strstr/teststrstr.cpp
	-pkill bluetcl
	rm -fr test-strstr
	mkdir test-strstr
	./genxpsprojfrombsv -B $(BOARD) -p test-strstr -b Strstr examples/strstr/Strstr.bsv bsv/BlueScope.bsv bsv/AxiSDMA.bsv bsv/PortalMemory.bsv -s examples/strstr/teststrstr.cpp
	cd test-strstr; make x86_exe; cd ..
	cd test-strstr; make bsim; cd ..
	test-strstr/sources/bsim &
	test-strstr/jni/strstr


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
	mkdir test-mempoke
	./genxpsprojfrombsv -B $(BOARD) -p test-mempoke -b Mempoke examples/mempoke/Mempoke.bsv bsv/BlueScope.bsv bsv/AxiSDMA.bsv bsv/PortalMemory.bsv -s examples/mempoke/testmempoke.cpp
	cd test-mempoke; make x86_exe; cd ..
	cd test-mempoke; make bsim; cd ..
	test-mempoke/sources/bsim &
	test-mempoke/jni/mempoke

test-ring/sources/bsim: examples/ring/Ring.bsv examples/ring/testring.cpp
	-pkill bluetcl
	rm -fr test-ring
	mkdir test-ring
	./genxpsprojfrombsv -B $(BOARD) -p test-ring -b Ring examples/ring/Ring.bsv examples/ring/RingTypes.bsv bsv/BlueScope.bsv bsv/AxiSDMA.bsv bsv/PortalMemory.bsv -s examples/ring/testring.cpp
	cd test-ring; make x86_exe; cd ..
	cd test-ring; make bsim; cd ..
#	test-ring/sources/bsim &
#	test-ring/jni/ring
