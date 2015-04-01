CONNECTALDIR?=../..

run: spiTestBench
	./spiTestBench
	gtkwave dump.vcd

spiTestBench: $(CONNECTALDIR)/lib/bsv/ConnectalSpi.bsv
	mkdir -p obj
	bsc -sim -bdir obj -p +:$(CONNECTALDIR)/lib/bsv -g mkSpiTestBench -u $(CONNECTALDIR)/lib/bsv/ConnectalSpi.bsv
	bsc -sim -bdir obj -e mkSpiTestBench -o spiTestBench
