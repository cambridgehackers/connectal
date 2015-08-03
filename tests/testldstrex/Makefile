CONNECTALDIR?=../..
TOOLCHAIN ?= /afs/csail.mit.edu/group/csg/tools/tools_lx86/android-ndk-r9d/sources/cxx-stl/gnu-libstdc++/4.6
MEM_INTERFACES = nil,nil

CPPFILES= testldstrex.cpp
CONNECTALFLAGS += -I $(TOOLCHAIN)/include -I $(TOOLCHAIN)/libs/armeabi-v7a/include

include $(CONNECTALDIR)/Makefile.connectal
