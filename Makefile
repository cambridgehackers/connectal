
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
	rm -fr test-memcpy
	mkdir test-memcpy
	./genxpsprojfrombsv -M bsim -B $(BOARD) -p test-memcpy -b Memcpy examples/memcpy/Memcpy.bsv bsv/BlueScope.bsv bsv/AxiSDMA.bsv bsv/PortalMemory.bsv
	cp examples/memcpy/testmemcpy.cpp test-memcpy/jni/
	cd test-memcpy; make x86_exe; cd ..
	test-memcpy/sources/bsim &
	test-memcpy/jni/memcpy


test-memread/sources/bsim: examples/memread/Memread.bsv examples/memread/testmemread.cpp
	rm -fr test-memread
	mkdir test-memread
	./genxpsprojfrombsv -M bsim -B $(BOARD) -p test-memread -b Memread examples/memread/Memread.bsv bsv/BlueScope.bsv bsv/AxiSDMA.bsv bsv/PortalMemory.bsv
	cp examples/memread/testmemread.cpp test-memread/jni/
	cd test-memread; make x86_exe; cd ..
	test-memread/sources/bsim &
	test-memread/jni/memread


test-memwrite/sources/bsim: examples/memwrite/Memwrite.bsv examples/memwrite/testmemwrite.cpp
	rm -fr test-memwrite
	mkdir test-memwrite
	./genxpsprojfrombsv -M bsim -B $(BOARD) -p test-memwrite -b Memwrite examples/memwrite/Memwrite.bsv bsv/BlueScope.bsv bsv/AxiSDMA.bsv bsv/PortalMemory.bsv
	cp examples/memwrite/testmemwrite.cpp test-memwrite/jni/
	cd test-memwrite; make x86_exe; cd ..
	test-memwrite/sources/bsim &
	test-memwrite/jni/memwrite

xilinx/pcie_7x_v2_1: scripts/generate-pcie.tcl
	rm -fr proj_pcie
	vivado -mode batch -source scripts/generate-pcie.tcl
	mv ./proj_pcie/proj_pcie.srcs/sources_1/ip/pcie_7x_0 xilinx/pcie_7x_v2_1
	rm -fr ./proj_pcie

