
BSVDIR=../../bsv
S2H = MemreadRequest DMARequest
H2S = MemreadIndication DMAIndication
BSVFILES = Memread.bsv  $(BSVDIR)/PortalMemory.bsv
CPPFILES=testmemread.cpp
DMA = Dma
PINS = Std

include ../../Makefile.common

mkTbPcie: mkTbPcie.ba
	bsc -sim -o mkTbPcie -e mkTbPcie obj/mkTbPcie.ba

mkTbPcie.ba: TbPcie.bsv Memread.bsv ../../bsv/AxiDMA.bsv ../../bsv/PcieToAxiBridge.bsv
	mkdir -p obj
	bsc --aggressive-conditions -show-schedule -D TimeStamp=22 -bdir $$PWD/obj -sim -u -g mkTbPcie -p +:../../bsv TbPcie.bsv
