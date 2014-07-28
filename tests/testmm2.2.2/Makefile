
BSCFLAGS=-aggressive-conditions -show-schedule -keep-fires -p +:../paclib

XBSVDIR=../..
DBNDIR=../../examples/testmm
DBNTOPBSV=    $(DBNDIR)/Top.bsv
TESTCPPFILES= $(DBNDIR)/testmm.cpp
XBSVFLAGS = -D J_VALUE=2 -D K_VALUE=2 -D N_VALUE=2 #-D INTERLEAVED
include $(DBNDIR)/Makefile.dbn

FPGAMAKE=$(XBSVDIR)/../fpgamake/fpgamake
IPDIR=$(XBSVDIR)/generated/xilinx/
XDC= --xdc=constraints/zc706.xdc --xdc=constraints/zc7z045ffg900.xdc 

synth.%:
	cd $*; BOARD=$* $(FPGAMAKE) -s mkMmTile -t mkZynqTop --xci=$(IPDIR)/$*/fp_add/fp_add.xci --xci=$(IPDIR)/$*/fp_mul/fp_mul.xci $(XDC) --floorplan=../$*_floorplan.xdc -o synth.mk verilog $(XBSVDIR)/verilog
