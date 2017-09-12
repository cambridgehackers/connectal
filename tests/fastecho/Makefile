CONNECTALDIR?=../..

S2H_INTERFACES = \
	FastEchoRequestA:FastEcho.requestA \
	FastEchoRequestB:FastEcho.requestB \
	FastEchoRequestC:FastEcho.requestC \
	FastEchoRequestD:FastEcho.requestD \

H2S_INTERFACES = \
	FastEcho:FastEchoIndicationA \
	FastEcho:FastEchoIndicationB \
	FastEcho:FastEchoIndicationC \
	FastEcho:FastEchoIndicationD \

BSVFILES = FastEcho.bsv
CPPFILES = testfastecho.cpp

# This matches the frequency of the original design where the bug was found
CONNECTALFLAGS += --mainclockperiod=32
CONNECTALFLAGS += -D GET_PUT_WITH_CLOCKS_USE_XILINX_FIFO
CONNECTALFLAGS += --xci=$(IPDIR)/$(BOARD)/dual_clock_axis_fifo_32x8/dual_clock_axis_fifo_32x8.xci

include $(CONNECTALDIR)/Makefile.connectal

