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
CONNECTALDIR?=../..
DMADIR=../dma/

include $(DMADIR)/Makefile

CONNECTALFLAGS += -D DataBusWidth=128
