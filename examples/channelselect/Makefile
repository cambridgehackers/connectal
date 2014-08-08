BSVDIR=../../bsv
S2H = ChannelSelectRequest
H2S = ChannelSelectIndication
BSVFILES = DDS.bsv ChannelSelect.bsv Top.bsv
CPPFILES=testChannelSelect.c
NUMBER_OF_MASTERS =0
#XBSVFLAGS=--bscflags " -D TRACE_AXI"

gentarget:: sine.bin


sine.bin: sinetable
	./sinetable >sine.bin

sinetable: sinetable.c
	cc -o sinetable sinetable.c -lm

include ../../Makefile.xbsv

