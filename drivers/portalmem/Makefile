obj-m += portalmem.o

export KROOT=$(DEVICE_XILINX_KERNEL)

CROSS_COMPILE?=arm-linux-gnueabi-
DRIVER_VERSION?=$(shell git log -n 1 --oneline -- portalmem.c portalmem.h)

ccflags-y := -D DRIVER_VERSION_RAW="$(DRIVER_VERSION)" -I$(PWD)/../..

default: portalmem.ko
	cp portalmem.ko ~/adb_scripts/

SIGNATURE_C_FILES = $(shell ls *.c)

portalmem_signature_file.h: $(SIGNATURE_C_FILES)
	md5sum *.c | grep -v mod.c | sed -f ../../scripts/driver_signature.sed >portalmem_signature_file.h

parallellaportalmem.ko: portalmem.h portalmem.c portalmem_signature_file.h
	@$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) parallella_defconfig
	@$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) oldconfig
	@$(MAKE) -j 8 ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) LOADADDR=0x8000 uImage
	@$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) M=$(PWD) DRIVER_VERSION="$(DRIVER_VERSION)" modules

portalmem.ko: portalmem.h portalmem.c portalmem_signature_file.h
	@$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) xilinx_zynq_portal_defconfig
	@$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) oldconfig
	@$(MAKE) -j 8 ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) zImage
	@$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) M=$(PWD) DRIVER_VERSION="$(DRIVER_VERSION)" modules

clean:
	@$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) M=$(PWD) clean
