
V?=0
ifeq ($(V),0)
Q=@
else
Q=
endif
CONNECTALDIR ?= $(PWD)/../..
include $(CONNECTALDIR)/Makefile.version

obj-m += zynqportal.o

DEFCONFIG?=xilinx_zynq_portal_atheros_sdio_defconfig
CROSS_COMPILE?=arm-linux-gnueabi-
KROOT?=$(CONNECTALDIR)/../linux-xlnx

ccflags-y := -I$(src)/../portalmem -I$(src)/../../cpp -I$(PWD)/../.. -I$(src)/../../generated/cpp \
	-DDRIVER_VERSION="\"$(VERSION)\""

zynqportal.ko: zynqportal.h zynqportal.c
	echo "$(VERSION)"
	$(Q)$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) $(DEFCONFIG)
	$(Q)$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) oldconfig
	$(Q)$(MAKE) -j 8 ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) zImage
	$(Q)$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) M=$(PWD) modules

parallellazynqportal.ko: zynqportal.h zynqportal.c
	echo "$(VERSION)"
	$(Q)$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) parallella_defconfig
	$(Q)$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) oldconfig
	$(Q)$(MAKE) -j 8 ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) LOADADDR=0x8000 uImage
	$(Q)$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) M=$(PWD) modules

clean:
	$(Q)$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) M=$(PWD) clean
