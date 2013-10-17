
all: parsetab.py

parsetab.py: syntax.py
	python syntax.py

test: test-echo/echo.bit.bin.gz test-memcpy/memcpy.bit.bin.gz test-hdmi/hdmidisplay.bit.bin.gz

test-echo/echo.bit.bin.gz: examples/echo/Echo.bsv
	rm -fr test-echo
	mkdir test-echo
	./genxpsprojfrombsv -B zedboard -p test-echo -b Echo examples/echo/Echo.bsv
	cd test-echo; make verilog && make bits && make echo.bit.bin.gz
	cp examples/echo/testecho.cpp test-echo/jni
	(cd test-echo; ndk-build)
	echo test-echo built successfully

test-memcpy/memcpy.bit.bin.gz: examples/memcpy/Memcpy.bsv
	rm -fr test-memcpy
	mkdir test-memcpy
	./genxpsprojfrombsv -B zedboard -p test-memcpy -b Memcpy examples/memcpy/Memcpy.bsv bsv/BlueScope.bsv bsv/AxiDMA.bsv
	cd test-memcpy; make verilog && make bits && make memcpy.bit.bin.gz
	cp examples/memcpy/testmemcpy.cpp test-memcpy/jni
	(cd test-memcpy; ndk-build)
	echo test-memcpy built successfully

test-hdmi/hdmidisplay.bit.bin.gz: bsv/HdmiDisplay.bsv
	rm -fr test-hdmi
	mkdir test-hdmi
	./genxpsprojfrombsv -B zedboard -p test-hdmi -b HdmiDisplay bsv/HdmiDisplay.bsv
	cd test-hdmi; make verilog && make bits && make hdmidisplay.bit.bin.gz
	echo test-hdmi built successfully

test-imageon/imageon.bit.bin.gz: examples/imageon/ImageCapture.bsv
	rm -fr test-imageon
	mkdir test-imageon
	./genxpsprojfrombsv -B zedboard -p test-imageon -b ImageCapture examples/imageon/ImageCapture.bsv
	cd test-imageon; make verilog && make bits && make imageon.bit.bin.gz
	echo test-imageon built successfully
