
S2H = ChannelSelectTestRequest
H2S = ChannelSelectTestIndication
BSVFILES = ChannelSelectTestInterfaces.bsv  Top.bsv
CPPFILES=testchannelselecttest.cpp
NUMBER_OF_MASTERS =0
#XBSVFLAGS=--bscflags " -D TRACE_AXI"

gentarget:: sine.bin

sine.bin: sinetable
	mkdir -p bluesim
	./sinetable >sine.bin
	cp sine.bin bluesim

sinetable: sinetable.c
	cc -o sinetable sinetable.c -lm

include ../../Makefile.xbsv
