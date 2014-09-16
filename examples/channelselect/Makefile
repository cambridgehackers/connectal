
S2H = ChannelSelectTestRequest
H2S = ChannelSelectTestIndication
BSVFILES = ChannelSelectTestInterfaces.bsv  Top.bsv
CPPFILES=testchannelselecttest.cpp
NUMBER_OF_MASTERS =0
#XBSVFLAGS=--bscflags " -D TRACE_AXI"

gentarget:: sine.bin

sine.bin: sinetable
	./sinetable >sine.bin

sinetable: sinetable.c
	cc -o sinetable sinetable.c -lm

include ../../Makefile.xbsv
