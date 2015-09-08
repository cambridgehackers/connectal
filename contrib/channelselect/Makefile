CONNECTALDIR?=../..
INTERFACES = ChannelSelectTestRequest DDSTestRequest ChannelSelectTestIndication DDSTestIndication

BSVFILES = ChannelSelectTestInterfaces.bsv  DDSTestInterfaces.bsv Top.bsv
CPPFILES=testchannelselecttest.cpp

gentarget:: sine.bin

sine.bin: sinetable
	mkdir -p bluesim
	./sinetable >sine.bin
	cp sine.bin bluesim

sinetable: sinetable.c
	cc -o sinetable sinetable.c -lm

include $(CONNECTALDIR)/Makefile.connectal
