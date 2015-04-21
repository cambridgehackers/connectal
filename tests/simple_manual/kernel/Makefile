
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

ifeq ($(BOARD),bluesim)
    HARDWARE_FLAGS=-DBSIM
endif

export KROOT=/lib/modules/$(shell uname -r)/build
CPPDIR=../../../cpp
BOARDDIR=../$(BOARD)/jni
DRIVERDIR=$(src)/../../../
CONNECTAL_MODULE_NAME:=connectaluser_$(USER)

KBUILD_EXTRA_SYMBOLS := $(DRIVERDIR)/drivers/pcieportal/Module.symvers \
      $(DRIVERDIR)/drivers/portalmem/Module.symvers

$(CONNECTAL_MODULE_NAME)-y := ../simple_manual.o \
     $(BOARDDIR)/SimpleIndication.o \
     $(BOARDDIR)/SimpleRequest.o \
     $(CPPDIR)/portal.o \
     $(CPPDIR)/transportSocket.o \
     $(CPPDIR)/kernel_module.o

$(CONNECTAL_MODULE_NAME)-n := $(CPPDIR)/dmaManager.o

obj-m := $(CONNECTAL_MODULE_NAME).o

ccflags-y := -I$(src)/.. -I$(DRIVERDIR) -I$(src)/$(CPPDIR) -I$(src)/$(BOARDDIR) $(HARDWARE_FLAGS)

default:
	$(MAKE) -C $(KROOT) M=$(PWD) modules

clean:
	$(MAKE) -C $(KROOT) M=$(PWD) clean
	rm -f a.out bsim_relay socket_for_bluesim tmp.bluesim.makefile.pid

CURRENTMOD=$(shell lsmod | grep $(CONNECTAL_MODULE_NAME))

run: host
ifeq ($(BOARD),bluesim)
	@echo running bsim
	../bluesim/bin/bsim& echo $$! >tmp.bluesim.makefile.pid
else
	fpgajtag ../$(BOARD)/bin/mkTop.bin.gz
endif
ifneq ("$(CURRENTMOD)", "")
	sudo rmmod $(CONNECTAL_MODULE_NAME)
	#sudo rmmod bdbm_drv
endif
	sudo modprobe pcieportal
	sudo modprobe portalmem
	sudo insmod $(CONNECTAL_MODULE_NAME).ko
	#sudo insmod bdbm_drv.ko
ifeq ($(BOARD),bluesim)
	CONNECTAL_MODULE_NAME=$(CONNECTAL_MODULE_NAME) ./bsim_relay
	kill `cat tmp.bluesim.makefile.pid`
	#killall bluetcl
endif
	sudo rmmod $(CONNECTAL_MODULE_NAME)
	#sudo rmmod bdbm_drv
	dmesg | tail -30
	@rm -f tmp.bluesim.makefile.pid

#
# Target for making userspace bsim_relay program
CINCL=../../..
HOSTSOURCES=$(CPPDIR)/bsim_relay.c $(CPPDIR)/sock_utils.c $(CPPDIR)/portalSocket.c $(CPPDIR)/portal.c

host: $(HOSTSOURCES)
ifeq ($(BOARD),bluesim)
	gcc -o bsim_relay -g -I$(CINCL)/cpp -I$(CINCL) -DNO_CPP_PORTAL_CODE -DNO_POLLER_SUPPORT $(HOSTSOURCES) -lpthread
endif
