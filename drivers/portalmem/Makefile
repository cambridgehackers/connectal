
V?=0
ifeq ($(V),0)
Q=@
else
Q=
endif
CONNECTALDIR ?= $(PWD)/../..
include $(CONNECTALDIR)/Makefile.version

obj-m = portalmem.o

ccflags-y := -I$(CONNECTALDIR) \
	-DDRIVER_VERSION="KBUILD_STR($(VERSION))"

ifeq ("$(KROOT)","")
KVERSION=$(shell uname -r)
export KROOT=/lib/modules/$(KVERSION)/build
else
CROSS_COMPILE?=arm-linux-gnueabi-
PARAM=ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE)
endif

.PHONY: portalmem_signature_file.h

portalmem.ko: portalmem.h portalmem.c portalmem_signature_file.h
ifneq ("$(PARAM)","")
	$(Q)$(MAKE) $(PARAM) -C $(KROOT) xilinx_zynq_portal_atheros_sdio_defconfig
	$(Q)$(MAKE) $(PARAM) -C $(KROOT) -j8 zImage
endif
	$(Q)$(MAKE) $(PARAM) -C $(KROOT) M=$(PWD) modules

portalmem_signature_file.h:
	md5sum *.c | grep -v mod.c | sed -f ../../scripts/driver_signature.sed >portalmem_signature_file.h

parallellaportalmem.ko: portalmem.h portalmem.c portalmem_signature_file.h
	$(Q)$(MAKE) $(PARAM) -C $(KROOT) parallella_defconfig
	$(Q)$(MAKE) $(PARAM) -C $(KROOT) -j8 LOADADDR=0x8000 uImage
	$(Q)$(MAKE) $(PARAM) -C $(KROOT) M=$(PWD) modules

clean:
	$(Q)$(MAKE) $(PARAM) -C $(KROOT) M=$(PWD) clean
