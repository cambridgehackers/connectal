
# grep get_pcie_portal_descriptor /proc/kallsyms 

BOARD=kc705

export KROOT=/lib/modules/$(shell uname -r)/build
CPPDIR=../../../cpp
BOARDDIR=../$(BOARD)/jni
DRIVERDIR=$(src)/../../../drivers

KBUILD_EXTRA_SYMBOLS := $(DRIVERDIR)/pcieportal/Module.symvers

testme-y := ../memread_manual_manager.o \
     $(BOARDDIR)/SimpleIndicationWrapper.o \
     $(BOARDDIR)/SimpleRequestProxy.o \
     $(CPPDIR)/portal.o \
     $(CPPDIR)/kernel_module.o

testme-y := $(CPPDIR)/dmaManager.o

obj-m := testme.o

ccflags-y := -I$(src)/.. -I$(DRIVERDIR)/pcieportal -I$(DRIVERDIR)/portalmem -I$(src)/$(CPPDIR) -I$(src)/$(BOARDDIR) -DMMAP_HW

default:
	$(MAKE) -C $(KROOT) M=$(PWD) modules

clean:
	$(MAKE) -C $(KROOT) M=$(PWD) clean
	rm -f a.out

