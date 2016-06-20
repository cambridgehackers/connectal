CONNECTALDIR?=../..
S2H_INTERFACES = EchoRequest:Echo.request
H2S_INTERFACES = Echo:EchoResponse

BSVFILES = EchoInterface.bsv
CPPFILES = $(CONNECTALDIR)/cpp/portalPython.cpp
CPPFILES2= $(CONNECTALDIR)/cpp/runpython.cpp
CONNECTALFLAGS += --shared
CONNECTALFLAGS += -D PORTAL_JSON
CONNECTALFLAGS += --run-args="$(PWD)/testecho.py $(CONNECTALDIR)/scripts/portal.py $(PWD)/$(BOARD)/bin/connectal.so"
ifneq ($(BOARD),zedboard)
CONNECTALFLAGS += -ljsoncpp
endif

ifeq ($(BOARD),zedboard)
## git clone git://github.com/cambridgehackers/python-for-android-sdk
PYTHON_FOR_ANDROID ?= $(CONNECTALDIR)/../python-for-android-sdk
CONNECTALFLAGS += -I$(PYTHON_FOR_ANDROID)/include/ -I.
CONNECTALFLAGS += -L$(PYTHON_FOR_ANDROID)/lib -lpython2.7
CONNECTALFLAGS += --stl=gnustl_static --cxxflags=-fexceptions --android-toolchain=4.8

CPPFILES  += jsoncpp/dist/jsoncpp.cpp
CPPFILES2 += jsoncpp/dist/jsoncpp.cpp

prebuild::
	[ -d jsoncpp ] || git clone git://github.com/open-source-parsers/jsoncpp
	cd jsoncpp; python amalgamate.py; mkdir -p json; cd json; ln -sf ../dist/json/*.h .
endif

ifeq ($(BOARD),zedboard_ubuntu)
CONNECTALFLAGS += --cxxflags=-std=c++11
CONNECTALFLAGS += -I usr/include
CONNECTALFLAGS += -L usr/lib/arm-linux-gnueabihf -lpython2.7

prebuild::
	./ubuntu-python-dev.sh
endif

include $(CONNECTALDIR)/Makefile.connectal
