
V?=0
ifeq ($(V),0)
Q=@
else
Q=
endif
CONNECTALDIR ?= $(PWD)/../..
include $(CONNECTALDIR)/Makefile.version

obj-m += portalmem.o

CROSS_COMPILE?=arm-linux-gnueabi-

ccflags-y := -I$(PWD)/../.. \
	-DDRIVER_VERSION="KBUILD_STR($(VERSION))"

default: portalmem.ko
	cp portalmem.ko ~/adb_scripts/

.PHONY: portalmem_signature_file.h

portalmem_signature_file.h:
	md5sum *.c | grep -v mod.c | sed -f ../../scripts/driver_signature.sed >portalmem_signature_file.h

parallellaportalmem.ko: portalmem.h portalmem.c portalmem_signature_file.h
	@$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) parallella_defconfig
	@$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) oldconfig
	@$(MAKE) -j 8 ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) LOADADDR=0x8000 uImage
	@$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) M=$(PWD) modules

portalmem.ko: portalmem.h portalmem.c portalmem_signature_file.h
	@$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) xilinx_zynq_portal_defconfig
	@$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) oldconfig
	@$(MAKE) -j 8 ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) zImage
	@$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) M=$(PWD) modules

clean:
	@$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) M=$(PWD) clean
