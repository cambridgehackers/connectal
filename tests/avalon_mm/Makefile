CONNECTALDIR?=../..
S2H_INTERFACES = EchoRequest:Echo.request
H2S_INTERFACES = Echo:EchoIndication

BSVFILES = Echo.bsv
CPPFILES= testecho.cpp

CONNECTALFLAGS += --verilog verilog
CONNECTALFLAGS += --systemverilog $(IPDIR)/$(BOARD)/synthesis/avlm_avls_1x1

prebuild::
	cd $(BOARD); BUILDCACHE_CACHEDIR=$(BUILDCACHE_CACHEDIR) $(BUILDCACHE) ip-generate \
	    --project-directory=$(IPDIR)/$(BOARD) \
	    --output-directory=$(IPDIR)/$(BOARD)/synthesis/avlm_avls_1x1 \
	    --report-file=spd \
	    --file-set=SIM_VERILOG \
	    ../avlm_avls_1x1.qsys; \
	    BUILDCACHE_CACHEDIR=$(BUILDCACHE_CACHEDIR) $(BUILDCACHE) ip-make-simscript \
	    --spd=$(IPDIR)/$(BOARD)/synthesis/avlm_avls_1x1/avlm_avls_1x1.spd \
	    --compile-to-work \
	    --output-directory=$(IPDIR)/$(BOARD)/synthesis/avlm_avls_1x1;

include $(CONNECTALDIR)/Makefile.connectal

