
BSVDIR=../../bsv
S2H = MemwriteRequest DmaConfig
H2S = MemwriteIndication DmaIndication
BSVFILES = Memwrite.bsv Top.bsv
CPPFILES=testmemwrite.cpp
#XBSVFLAGS=--bscflags " -D TRACE_AXI"

include ../../Makefile.common

mkTbPcie: mkTbPcie.ba
	bsc -sim -o mkTbPcie -e mkTbPcie obj/mkTbPcie.ba

mkTbPcie.ba: TbPcie.bsv ../../bsv/AxiDma.bsv ../../bsv/PcieToAxiBridge.bsv
	mkdir -p obj
	bsc --aggressive-conditions -show-schedule -D TimeStamp=22 -bdir $$PWD/obj -sim -u -g mkTbPcie -p +:../../bsv TbPcie.bsv
