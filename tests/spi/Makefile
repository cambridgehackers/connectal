CONNECTALDIR?=../..

run: spiTestBench
	./spiTestBench
	gtkwave dump.vcd spitest.gtkw

spiTestBench: $(CONNECTALDIR)/lib/bsv/ConnectalSpi.bsv
	mkdir -p obj
	bsc --show-schedule -sim -info-dir obj -bdir obj -p +:$(CONNECTALDIR)/lib/bsv -g mkSpiTestBench -u $(CONNECTALDIR)/lib/bsv/ConnectalSpi.bsv
	bsc --show-schedule -sim -info-dir obj -bdir obj -e mkSpiTestBench -o spiTestBench
