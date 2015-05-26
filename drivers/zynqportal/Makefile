
V?=0
ifeq ($(V),0)
Q=@
else
Q=
endif
CONNECTALDIR ?= $(PWD)/../..
include $(CONNECTALDIR)/Makefile.version

obj-m += zynqportal.o

CROSS_COMPILE?=arm-linux-gnueabi-

ccflags-y := -I$(src)/../portalmem -I$(src)/../../cpp -I$(PWD)/../.. -I$(src)/../../generated/cpp \
	-DDRIVER_VERSION="KBUILD_STR($(VERSION))"

default: zynqportal.ko
	echo "$(VERSION)"
	cp zynqportal.ko ~/adb_scripts/

zynqportal.ko: zynqportal.h zynqportal.c
	echo "$(VERSION)"
	$(Q)md5sum *.c ../../generated/cpp/*.c | grep -v mod.c | sed -f ../../scripts/driver_signature.sed >driver_signature_file.h
	$(Q)$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) xilinx_zynq_portal_defconfig
	$(Q)$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) oldconfig
	$(Q)$(MAKE) -j 8 ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) zImage
	$(Q)$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) M=$(PWD) modules

parallellazynqportal.ko: zynqportal.h zynqportal.c
	echo "$(VERSION)"
	$(Q)md5sum *.c ../../generated/cpp/*.c | grep -v mod.c | sed -f ../../../scripts/driver_signature.sed >driver_signature_file.h
	$(Q)$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) parallella_defconfig
	$(Q)$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) oldconfig
	$(Q)$(MAKE) -j 8 ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) LOADADDR=0x8000 uImage
	$(Q)$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) M=$(PWD) modules

clean:
	$(Q)$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) M=$(PWD) clean
	rm -f driver_signature_file.h
