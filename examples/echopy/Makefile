CONNECTALDIR?=../..
S2H_INTERFACES = EchoRequest:Echo.request
H2S_INTERFACES = Echo:EchoResponse

BSVFILES = EchoInterface.bsv
CPPFILES = $(CONNECTALDIR)/cpp/portalPython.cpp
CPPFILES2= $(CONNECTALDIR)/cpp/runpython.cpp
CONNECTALFLAGS += --shared
CONNECTALFLAGS += --run-args="$(PWD)/testecho.py $(CONNECTALDIR)/scripts/portal.py $(PWD)/$(BOARD)/bin/connectal.so"
ifeq ($(BOARD),zedboard)
## git clone git://github.com/cambridgehackers/python-for-android-sdk
PYTHON_FOR_ANDROID ?= $(CONNECTALDIR)/../python-for-android-sdk
CONNECTALFLAGS += -I$(PYTHON_FOR_ANDROID)/include/
CONNECTALFLAGS += -L$(PYTHON_FOR_ANDROID)/lib -lpython2.7
endif
ifeq ($(BOARD),zedboard_ubuntu)
CONNECTALFLAGS += -I usr/include
CONNECTALFLAGS += -L usr/lib/python2.7/config-arm-linux-gnueabihf -lpython2.7
endif

prebuild::
	./ubuntu-python-dev.sh

include $(CONNECTALDIR)/Makefile.connectal
