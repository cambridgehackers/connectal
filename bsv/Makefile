

test: testspi

testspi: XbsvSpi.bsv
	bsc -sim -u -g mkSpiTestBench XbsvSpi.bsv
	bsc -sim -u -e mkSpiTestBench -o spiTestBench mkSpiTestBench.ba
	./spiTestBench

testgearbox: GearboxTb.bsv
	bsc -sim -u -g mkGearboxTb GearboxTb.bsv
	bsc -sim -u -e mkGearboxTb -o testGearbox mkGearboxTb.ba
	./testGearbox

mkGearboxTb.v: GearboxTb.bsv
	bsc -verilog -u -g mkGearboxTb GearboxTb.bsv

mkSPI20.v: XbsvSpi.bsv
	bsc -verilog -u -g mkSPI20 XbsvSpi.bsv


