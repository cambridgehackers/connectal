
BSVDIR=../../bsv
S2H = MemwriteRequest DMARequest
H2S = MemwriteIndication DMAIndication
BSVFILES = Memwrite.bsv  $(BSVDIR)/PortalMemory.bsv
CPPFILES=testmemwrite.cpp
DMA = Dma
PINS = Std

include ../../Makefile.common

mkTbPcie: mkTbPcie.ba
	bsc -sim -o mkTbPcie -e mkTbPcie obj/mkTbPcie.ba

mkTbPcie.ba: TbPcie.bsv ../../bsv/AxiRDMA.bsv ../../bsv/PcieToAxiBridge.bsv
	mkdir -p obj
	bsc --aggressive-conditions -show-schedule -D TimeStamp=22 -bdir $$PWD/obj -sim -u -g mkTbPcie -p +:../../bsv TbPcie.bsv
