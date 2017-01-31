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

include $(CONNECTALDIR)/Makefile.connectal

