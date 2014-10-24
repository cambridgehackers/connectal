S2H = Tiny3Request
H2S = Tiny3Indication
BSVFILES = TinyTestTypes.bsv Top.bsv
CPPFILES=testtiny3.cpp
NUMBER_OF_MASTERS =0

include ../../Makefile.connectal


testbench:
	bsc -sim -aggressive-conditions -u -g mkTinyTestBench TinyTestBench.bsv
	bsc -sim -aggressive-conditions -e mkTinyTestBench mkTinyTestBench.ba
	./a.out
clean:
	-rm a.out* mkTestBench.* model*
	-rm *.bo
