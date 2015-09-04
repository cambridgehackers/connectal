CONNECTALDIR?=../..
S2H_INTERFACES = EchoRequest:Echo.request
H2S_INTERFACES = Echo:EchoIndication

CPPFILES=testecho.cpp
#CONNECTALFLAGS += --protobuf interface.json
CONNECTALFLAGS += --protobuf echo_pb.json

include $(CONNECTALDIR)/Makefile.connectal

prebuild::
	$(CONNECTALDIR)/../protobuf/src/protoc --cpp_out=. --bsv_out=. echo.proto
