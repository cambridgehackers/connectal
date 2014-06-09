
BSVDIR=../../bsv
S2H = MemreadRequest DmaConfig
H2S = MemreadIndication DmaIndication
BSVFILES = Memread.bsv Top.bsv
CPPFILES=testmemread.cpp
XBSVFLAGS += -D NumberOfMasters=4
#XBSVFLAGS=--bscflags " -D TRACE_AXI"

include ../../Makefile.common

mkTbPcie: mkTbPcie.ba
	bsc -sim -o mkTbPcie -e mkTbPcie obj/mkTbPcie.ba

mkTbPcie.ba: TbPcie.bsv Memread.bsv ../../bsv/AxiDma.bsv ../../bsv/PcieToAxiBridge.bsv
	mkdir -p obj
	bsc --aggressive-conditions -show-schedule -D TimeStamp=22 -bdir $$PWD/obj -sim -u -g mkTbPcie -p +:../../bsv TbPcie.bsv
