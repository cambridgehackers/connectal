
V?=0
ifeq ($(V),0)
Q=@
else
Q=
endif
DEFCONFIG ?= xilinx_zynq_portal_atheros_sdio_defconfig
CONNECTALDIR ?= $(PWD)/../..
include $(CONNECTALDIR)/Makefile.version

obj-m = portalmem.o

ccflags-y := -I$(CONNECTALDIR)

ifeq ("$(KROOT)","")
KVERSION=$(shell uname -r)
export KROOT=/lib/modules/$(KVERSION)/build
else
CROSS_COMPILE?=arm-linux-gnueabi-
PARAM=ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE)
endif

portalmem.ko: portalmem.h portalmem.c driverversion.h
ifneq ("$(PARAM)","")
	$(Q)$(MAKE) $(PARAM) -C $(KROOT) $(DEFCONFIG)
	$(Q)$(MAKE) $(PARAM) -C $(KROOT) -j8 zImage
endif
	$(Q)$(MAKE) $(PARAM) -C $(KROOT) M=$(PWD) modules

driverversion.h:
	VERSION=$(VERSION) echo "#define DRIVER_VERSION \"$VERSION\"" > driverversion.h

parallellaportalmem.ko: portalmem.h portalmem.c
	$(Q)$(MAKE) $(PARAM) -C $(KROOT) parallella_defconfig
	$(Q)$(MAKE) $(PARAM) -C $(KROOT) -j8 LOADADDR=0x8000 uImage
	$(Q)$(MAKE) $(PARAM) -C $(KROOT) M=$(PWD) modules

clean:
	$(Q)$(MAKE) $(PARAM) -C $(KROOT) M=$(PWD) clean
