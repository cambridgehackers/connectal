
## software interfaces invoked from software (requests)
S2S = SRequest SIndication MMUConfigRequest MMUConfigIndication
## hardware interfaces invoked from software (requests)
S2H = Swallow EchoRequest
## software interfaces invoked from hardware (indications)
H2S = EchoIndication
## all the BSV files to be scanned for types and interfaces
BSVFILES = Echo.bsv Swallow.bsv Top.bsv Soft.bsv
BSVFILES += $(CONNECTALDIR)/bsv/ConnectalMemory.bsv
## the source files in the example
CPPFILES=daemon.cpp
CPPFILES2=testecho.cpp

NUMBER_OF_MASTERS =0

include ../../Makefile.connectal
