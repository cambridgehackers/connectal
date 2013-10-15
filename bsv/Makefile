

test: testspi testAdapter

testspi: XbsvSpi.bsv
	bsc -check-assert -sim -u -g mkSpiTestBench XbsvSpi.bsv
	bsc -check-assert -sim -u -e mkSpiTestBench -o spiTestBench mkSpiTestBench.ba
	./spiTestBench -V spi.vcd

testgearbox: GearboxTb.bsv
	bsc -sim -u -g mkGearboxTb GearboxTb.bsv
	bsc -sim -u -e mkGearboxTb -o testGearbox mkGearboxTb.ba
	./testGearbox

mkGearboxTb.v: GearboxTb.bsv
	bsc -verilog -u -g mkGearboxTb GearboxTb.bsv

testAdapter: Adapter.bsv
	bsc -check-assert -sim -u -g mkAdapterTb Adapter.bsv
	bsc -check-assert -sim -u -e mkAdapterTb -o testAdapter mkAdapterTb.ba
	./testAdapter

mkSPI20.v: XbsvSpi.bsv
	bsc -verilog -u -g mkSPI20 XbsvSpi.bsv
