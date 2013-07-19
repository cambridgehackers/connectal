
all: parsetab.py

parsetab.py: syntax.py
	python syntax.py

test: test-echo/echo.bit.bin.gz test-memcpy/memcpy.bit.bin.gz test-hdmi/hdmidisplay.bit.bin.gz

test-echo/echo.bit.bin.gz: examples/echo/Echo.bsv
	rm -fr test-echo
	mkdir test-echo
	(./genxpsprojfrombsv -B zedboard -p echoproj -b Echo examples/echo/Echo.bsv; cd echoproj; make verilog && make bits && make echo.bit.bin.gz) > test-echo/test-echo.log 2>&1
	echo test-echo built successfully

test-memcpy/memcpy.bit.bin.gz: examples/memcpy/Memcpy.bsv
	rm -fr test-memcpy
	mkdir test-memcpy
	(./genxpsprojfrombsv -B zedboard -p memcpyproj -b Memcpy examples/memcpy/Memcpy.bsv; cd memcpyproj; make verilog && make bits && make memcpy.bit.bin.gz) > test-memcpy/test-memcpy.log 2>&1
	echo test-memcpy built successfully

test-hdmi/hdmidisplay.bit.bin.gz: bsv/HdmiDisplay.bsv
	rm -fr test-hdmi
	mkdir test-hdmi
	(./genxpsprojfrombsv -B zedboard -p hdmiproj -b HdmiDisplay bsv/HdmiDisplay.bsv; cd hdmiproj; make verilog && make bits && make hdmidisplay.bit.bin.gz) > test-hdmi/test-hdmi.log 2>&1
	echo test-hdmi built successfully

