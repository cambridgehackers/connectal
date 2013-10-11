

test: testspi

testspi: SPI.bsv
	bsc -sim -u -g mkSpiTestBench SPI.bsv
	bsc -sim -u -e mkSpiTestBench -o spiTestBench mkSpiTestBench.ba
	./spiTestBench; echo $?

testgearbox: GearboxTb.bsv
	bsc -sim -u -g mkGearboxTb GearboxTb.bsv
	bsc -sim -u -e mkGearboxTb -o testGearbox mkGearboxTb.ba
	.testGearbox

