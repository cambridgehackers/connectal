
S2H = ChannelSelectTestRequest
H2S = ChannelSelectTestIndication
BSVFILES = DDS.bsv ChannelSelect.bsv FPCMult.bsv ChannelSelectTest.bsv Top.bsv
CPPFILES=testChannelSelect.c
NUMBER_OF_MASTERS =0
#XBSVFLAGS=--bscflags " -D TRACE_AXI"

gentarget:: sine.bin

sine.bin: sinetable
	./sinetable >sine.bin

sinetable: ../fmcomms1/sinetable.c
	cc -o sinetable ../fmcomms1/sinetable.c -lm

include ../../Makefile.xbsv
