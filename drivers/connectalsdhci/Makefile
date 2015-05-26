
V?=0
ifeq ($(V),0)
Q=@
else
Q=
endif
CONNECTALDIR ?= $(PWD)/../..
include $(CONNECTALDIR)/Makefile.version

obj-m += connectalsdhci.o

CROSS_COMPILE?=arm-linux-gnueabi-

ccflags-y := -I$(src)/../portalmem -I$(src)/../../cpp -I$(PWD)/../.. -I$(src)/../../generated/cpp \
	-DDRIVER_VERSION="KBUILD_STR($(VERSION))"

connectalsdhci.ko: connectalsdhci.c
	@$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) xilinx_zynq_portal_defconfig
	@$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) oldconfig
	@$(MAKE) -j 8 ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) zImage
	@$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) M=$(PWD) modules

clean:
	@$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) M=$(PWD) clean
