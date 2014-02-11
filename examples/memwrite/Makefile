
BSVDIR=../../bsv
S2H = MemwriteRequest DmaConfig
H2S = MemwriteIndication DmaIndication
BSVFILES = Memwrite.bsv
CPPFILES=testmemwrite.cpp
Dma = Dma
PINS = Std

ifeq ($(BOARD),bluesim)
// sock_fd.cxx already included
else
CPPFILES += $(XBSVDIR)/cpp/sock_fd.cxx
endif

include ../../Makefile.common

mkTbPcie: mkTbPcie.ba
	bsc -sim -o mkTbPcie -e mkTbPcie obj/mkTbPcie.ba

mkTbPcie.ba: TbPcie.bsv ../../bsv/AxiDma.bsv ../../bsv/PcieToAxiBridge.bsv
	mkdir -p obj
	bsc --aggressive-conditions -show-schedule -D TimeStamp=22 -bdir $$PWD/obj -sim -u -g mkTbPcie -p +:../../bsv TbPcie.bsv
