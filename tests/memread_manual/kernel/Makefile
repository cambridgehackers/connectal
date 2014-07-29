
# grep get_pcie_portal_descriptor /proc/kallsyms 

###################### Flags for using KC705   ###################
#BOARD=kc705
###################### Flags for using VC707   ###################
#BOARD=vc707
###################### Flags for using zedboard ##################
#BOARD=zedboard
###################### Flags for using Bluesim ###################
BOARD=bluesim
###################### End of target h/w flags ###################

ifneq ($(BOARD),bluesim)
    HARDWARE_FLAGS=-DMMAP_HW
endif

export KROOT=/lib/modules/$(shell uname -r)/build
CPPDIR=../../../cpp
BOARDDIR=../$(BOARD)/jni
DRIVERDIR=$(src)/../../../drivers

KBUILD_EXTRA_SYMBOLS := $(DRIVERDIR)/pcieportal/Module.symvers $(DRIVERDIR)/portalmem/Module.symvers

kernel_exe-y := ../memread_manual_manager.o \
     $(BOARDDIR)/DmaConfigProxy.o \
     $(BOARDDIR)/DmaIndicationWrapper.o \
     $(BOARDDIR)/MemreadIndicationWrapper.o \
     $(BOARDDIR)/MemreadRequestProxy.o \
     $(CPPDIR)/portal.o \
     $(CPPDIR)/dmaManager.o \
     $(CPPDIR)/sock_utils.o \
     $(CPPDIR)/kernel_module.o

obj-m := kernel_exe.o

ccflags-y := -I$(src)/.. -I$(DRIVERDIR)/pcieportal -I$(DRIVERDIR)/portalmem -I$(src)/$(CPPDIR) -I$(src)/$(BOARDDIR) $(HARDWARE_FLAGS)

default:
	$(MAKE) -C $(KROOT) M=$(PWD) modules

clean:
	$(MAKE) -C $(KROOT) M=$(PWD) clean
	rm -f $(kernel_exe-y) a.out
