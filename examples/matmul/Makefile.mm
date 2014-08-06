BSVDIR=$(XBSVDIR)/bsv
S2H = RbmRequest  MmRequestTN MmRequestNT SigmoidRequest TimerRequest DmaConfig FpMacRequest FpMulRequest MmDebugRequest 
H2S = RbmIndication MmIndication SigmoidIndication TimerIndication DmaIndication FpMacIndication FpMulIndication MmDebugIndication
BSVFILES = $(RBMDIR)/bsv/RbmTypes.bsv $(RBMDIR)/bsv/Timer.bsv $(MMDIR)/bsv/FpMacTb.bsv $(DBNTOPBSV)
CPPFILES= $(MMDIR)/cpp/portalmat.cpp $(TESTCPPFILES)
XBSVFLAGS += --clib opencv_core --stl=stlport_static
XBSVFLAGS += -D IMPORT_HOSTIF -D MATRIX_TN -D ZYNQ_NO_RESET
XBSVFLAGS += --bscflags="+RTS -K26777216 -RTS"

Dma = Dma
PINS = Std

FAMILY=$(shell echo $(BOARD) | sed 's/z.*/zynq/' | sed 's/k.*/kintex/' | sed 's/v.*/virtex/')

##
## To build testmm for Android on Zynq
## cd $(XBSVDIR); cd ..; git clone git://github.com:cambridgehackers/opencv-android-sdk.git
##

ifeq (zynq,$(FAMILY))
NDK_DIR=$(shell ndk-which gcc | sed 's:toolchains.*::')
OPENCVDIR=$(XBSVDIR)/../opencv-android-sdk/sdk/native/
XBSVFLAGS += -I$(MMDIR)/cpp -I$(OPENCVDIR)/jni/include -L$(OPENCVDIR)/libs/armeabi-v7a -lz
XBSVFLAGS += -S$(NDK_DIR)/sources/cxx-stl/stlport/libs/armeabi-v7a/libstlport_static.a
NUMBER_OF_MASTERS=2
endif
ifeq (bluesim,$(FAMILY))
NUMBER_OF_MASTERS=2
endif

synth-ip.tcl:
	ln -svf $(XBSVDIR)/examples/matmul/synth-ip.tcl .

prebuild:: synth-ip.tcl
	if [ "$(BOARD)" != "bluesim" ] ; then cd $(BOARD); vivado -mode batch -source ../synth-ip.tcl; fi

include $(XBSVDIR)/Makefile.common

FPGAMAKE_XBSVFLAGS += -P mkMmTile --xci=$(IPDIR)/$(BOARD)/fp_add/fp_add.xci --xci=$(IPDIR)/$(BOARD)/fp_mul/fp_mul.xci
