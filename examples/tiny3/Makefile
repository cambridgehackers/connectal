
CONNECTALDIR?=../..
INTERFACES = Tiny3Request Tiny3Indication
BSVFILES = TinyTestTypes.bsv Top.bsv
CPPFILES=testtiny3.cpp
NUMBER_OF_MASTERS =0

include $(CONNECTALDIR)/Makefile.connectal


testbench:
	bsc -sim -show-schedule -aggressive-conditions -u -g mkTinyTestBench TinyTestBench.bsv
	bsc -sim -show-schedule -aggressive-conditions -e mkTinyTestBench mkTinyTestBench.ba
	./a.out
clean:
	-rm a.out* mkTestBench.* model*
	-rm *.bo
