##
## Before building:
##     sudo apt-add-repository ppa:jamey-hicks/connectal
##     sudo apt-get update
##     sudo apt-get install connectal
##
## To build for bluesim simulation using packaged connectal:
##     make CONNECTALDIR=/usr/share/connectal build.bluesim
##
## To simulate with bluesim:
##     ./bluesim/bin/bsim_exe
##
## To build for vc707 pcie gen2:
##     make CONNECTALDIR=/usr/share/connectal build.vc707g2
##
## To run on vc707:
##     ./vc707g2/bin/ubuntu.exe
##

## default location of connectal
CONNECTALDIR?=../..

## refer to the files in this directory via $(DMADIR)/ because this Makefile is included in ../dma128/Makefile
DMADIR=../dma/

S2H_INTERFACES = DmaRequest:DmaLoopback.request0,request1 LoopbackControl:DmaLoopback.control
H2S_INTERFACES = DmaLoopback:DmaIndication,DmaIndication
MEM_READ_INTERFACES = lDmaLoopback.readClient
MEM_WRITE_INTERFACES = lDmaLoopback.writeClient
BSVFILES = $(DMADIR)/DmaController.bsv $(DMADIR)/Interfaces.bsv
CPPFILES= $(DMADIR)/testdmacopy.cpp

include $(CONNECTALDIR)/Makefile.connectal

CONNECTALFLAGS += -D USE_DUAL_CLOCK_FIFOF
