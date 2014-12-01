
# grep get_pcie_portal_descriptor /proc/kallsyms 

###################### Flags for using KC705   ###################
#BOARD=kc705
###################### Flags for using VC707   ###################
BOARD=vc707
###################### Flags for using zedboard ##################
#BOARD=zedboard
###################### Flags for using Bluesim ###################
#BOARD=bluesim
###################### End of target h/w flags ###################

ifeq ($(BOARD),bluesim)
    HARDWARE_FLAGS=-DBSIM
endif

export KROOT=/lib/modules/$(shell uname -r)/build
CPPDIR=../../../cpp
BOARDDIR=../$(BOARD)/jni
DRIVERDIR=$(src)/../../../drivers

KBUILD_EXTRA_SYMBOLS := $(DRIVERDIR)/pcieportal/Module.symvers $(DRIVERDIR)/portalmem/Module.symvers

   #$(BOARDDIR)/DmaConfigProxy.o \
     #$(BOARDDIR)/DmaIndicationWrapper.o \


kernel_exe-y := ../nandsim_manual.o \
     $(BOARDDIR)/MMURequestProxy.o \
     $(BOARDDIR)/MMUIndicationWrapper.o \
     $(BOARDDIR)/MemServerRequestProxy.o \
     $(BOARDDIR)/MemServerIndicationWrapper.o \
     $(BOARDDIR)/NandCfgIndicationWrapper.o \
     $(BOARDDIR)/NandCfgRequestProxy.o \
     $(CPPDIR)/portal.o \
     $(CPPDIR)/dmaManager.o \
     $(CPPDIR)/kernel_module.o

ifeq ($(BOARD),bluesim)
kernel_exe-y += $(CPPDIR)/sock_utils.o
endif

obj-m := kernel_exe.o

ccflags-y := -I$(src)/.. -I$(DRIVERDIR)/pcieportal -I$(DRIVERDIR)/portalmem -I$(src)/$(CPPDIR) -I$(src)/$(BOARDDIR) $(HARDWARE_FLAGS) -DBOARD_$(BOARD)

default:
	$(MAKE) -C $(KROOT) M=$(PWD) modules

clean:
	$(MAKE) -C $(KROOT) M=$(PWD) clean
	rm -f $(kernel_exe-y) a.out bsim_relay

CURRENTMOD=$(shell lsmod | grep kernel_exe)

run: host
ifeq ($(BOARD),bluesim)
	@echo running bsim
	../bluesim/bin/bsim& echo $$! >tmp.bluesim.makefile.pid
else
	fpgajtag ../$(BOARD)/bin/mkTop.bin.gz
endif
ifneq ("$(CURRENTMOD)", "")
	sudo rmmod kernel_exe
	#sudo rmmod bdbm_drv
endif
	sudo insmod kernel_exe.ko
	#sudo insmod bdbm_drv.ko
ifeq ($(BOARD),bluesim)
	./bsim_relay
	kill `cat tmp.bluesim.makefile.pid`
	#killall bluetcl
endif
	sudo rmmod kernel_exe
	#sudo rmmod bdbm_drv
	dmesg | tail -30
	@rm -f tmp.bluesim.makefile.pid

#
# Target for making userspace bsim_relay program
CPPDIR=../../../cpp
HOSTSOURCES=$(CPPDIR)/bsim_relay.c $(CPPDIR)/sock_utils.c

host: $(HOSTSOURCES)
ifeq ($(BOARD),bluesim)
	gcc -o bsim_relay -g -I$(CPPDIR) $(HOSTSOURCES) -lpthread
endif
