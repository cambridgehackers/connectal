S2H = Tiny3Request
H2S = Tiny3Indication
BSVFILES = Tiny3.bsv Top.bsv
CPPFILES=testtiny3.cpp
NUMBER_OF_MASTERS =0

include ../../Makefile.xbsv


testbench:
	bsc -sim -aggressive-conditions -u -g mkTestBenchA TinyTestBench.bsv
	bsc -sim -aggressive-conditions -e mkTestBenchA mkTestBenchA.ba
	./a.out

clean:
	-rm a.out* mkTestBenchA.* model*
	-rm *.bo
