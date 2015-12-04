
BSVFILES   +=  $(CONNECTALDIR)/lib/rbm/bsv/RbmTypes.bsv $(CONNECTALDIR)/lib/rbm/bsv/Timer.bsv
CPPFILES   +=  $(CONNECTALDIR)/lib/matmul/cpp/portalmat.cpp $(TESTCPPFILES)

CONNECTALFLAGS  +=  -D IMPORT_HOSTIF -D MATRIX_TN -D MATMUL_HACK
CONNECTALFLAGS  +=  --bscflags="+RTS -K26777216 -RTS"
CONNECTALFLAGS  +=  --bsvpath $(CONNECTALDIR)/lib/matmul/bsv
CONNECTALFLAGS  += -I$(CONNECTALDIR)/lib/matmul/cpp

Dma = Dma
PINS = Std

FAMILY=$(shell echo $(BOARD) | sed 's/z.*/zynq/' | sed 's/k.*/kintex/' | sed 's/v.*/virtex/' | sed 's/miniitx.*/zynq/')

##
## To build testmm for Android on Zynq
## cd $(CONNECTALDIR); cd ..; git clone git://github.com:cambridgehackers/opencv-android-sdk.git
##

ifdef CUDA_PERF_TEST
OPENCVDIR=/scratch/opencv-cuda/opencv-2.4.9/install/
CONNECTALFLAGS  += -I$(OPENCVDIR)/include
CONNECTALFLAGS  += -L$(OPENCVDIR)/lib
CONNECTALFLAGS  += -L/usr/local/cuda-5.5/lib64
CONNECTALFLAGS  += --stl=stlport_static
CONNECTALFLAGS  += --clib z
CONNECTALFLAGS  += --clib cuda
CONNECTALFLAGS  += --clib cudart
CONNECTALFLAGS  += --clib nppi
CONNECTALFLAGS  += --clib nppc
CONNECTALFLAGS  += --clib npps
CONNECTALFLAGS  += --clib cufft
CONNECTALFLAGS  += --clib opencv_core
CONNECTALFLAGS  += --clib opencv_gpu
CONNECTALFLAGS  += --clib opencv_imgproc
CONNECTALFLAGS  += --clib opencv_core
CONNECTALFLAGS  += --clib opencv_objdetect
CONNECTALFLAGS  += --clib opencv_imgproc
CONNECTALFLAGS  += --clib cublas
CPPFILES   +=  $(CONNECTALDIR)/lib/matmul/cpp/cuda.cpp 
else
CONNECTALFLAGS  +=  --clib opencv_core --stl=stlport_static
endif

ifeq (zynq,$(FAMILY))
NDK_DIR=$(shell ndk-which gcc | sed 's:toolchains.*::')
OPENCVDIR=$(CONNECTALDIR)/../opencv-android-sdk/sdk/native/
CONNECTALFLAGS += -I$(CONNECTALDIR)/lib/matmul/cpp -I$(OPENCVDIR)/jni/include -L$(OPENCVDIR)/libs/armeabi-v7a -lz
CONNECTALFLAGS += -S$(NDK_DIR)/sources/cxx-stl/stlport/libs/armeabi-v7a/libstlport_static.a
PLATFORM_NUMBER_OF_MASTERS=2
endif
ifeq (bluesim,$(FAMILY))
PLATFORM_NUMBER_OF_MASTERS=2
endif

synth-ip.tcl:
	ln -svf $(CONNECTALDIR)/examples/matmul/synth-ip.tcl .

prebuild:: synth-ip.tcl
	if [ "$(BOARD)" != "bluesim" -a "$(BOARD)" != verilator ] ; then cd $(BOARD); BUILDCACHE_CACHEDIR=$(BUILDCACHE_CACHEDIR) $(BUILDCACHE) vivado -notrace -mode batch -source ../synth-ip.tcl; fi

FPGAMAKE_CONNECTALFLAGS += -P mkMmTile --xci=$(IPDIR)/$(BOARD)/fp_add/fp_add.xci --xci=$(IPDIR)/$(BOARD)/fp_mul/fp_mul.xci

