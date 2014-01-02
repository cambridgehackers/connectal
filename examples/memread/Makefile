
BSVDIR=../../bsv
S2H = MemreadRequest BlueScopeRequest DMARequest
H2S = MemreadIndication BlueScopeIndication DMAIndication
BSVFILES = Memread.bsv $(BSVDIR)/BlueScope.bsv $(BSVDIR)/PortalMemory.bsv
CPPFILES=testmemread.cpp

include ../../Makefile.common

mkTbPcie: mkTbPcie.ba
	bsc -sim -o mkTbPcie -e mkTbPcie obj/mkTbPcie.ba

mkTbPcie.ba: TbPcie.bsv Memread.bsv ../../bsv/AxiRDMA.bsv ../../bsv/PcieToAxiBridge.bsv
	mkdir -p obj
	bsc --aggressive-conditions -show-schedule -D TimeStamp=22 -bdir $$PWD/obj -sim -u -g mkTbPcie -p +:../../bsv TbPcie.bsv
