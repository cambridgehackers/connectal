obj-m += zynqportal.o

export KROOT=$(DEVICE_XILINX_KERNEL)

CROSS_COMPILE?=arm-none-linux-gnueabi-
DRIVER_VERSION?=$(shell git log -n 1 --oneline -- zynqportal.c zynqportal.h ../../cpp/dmaSendFd.h | cut -f 1 -d " ")

ccflags-y := -I$(src)/../portalmem -I$(src)/../../cpp -I$(PWD)/../.. -I$(src)/../../generated/cpp -D DRIVER_VERSION_RAW="$(DRIVER_VERSION)"

default: zynqportal.ko
	echo "$(DRIVER_VERSION)"
	cp zynqportal.ko ~/adb_scripts/

zynqportal.ko: zynqportal.h zynqportal.c
	echo "$(DRIVER_VERSION)"
	@$(MAKEKERNEL) $(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) xilinx_zynq_portal_defconfig
	@$(MAKEKERNEL) $(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) oldconfig
	@$(MAKEKERNEL) $(MAKE) -j 8 ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) zImage
	@$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) M=$(PWD) DRIVER_VERSION="$(DRIVER_VERSION)" modules

parallellazynqportal.ko: zynqportal.h zynqportal.c
	echo "$(DRIVER_VERSION)"
	@$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) parallella_defconfig
	@$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) oldconfig
	@$(MAKE) -j 8 ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) LOADADDR=0x8000 uImage
	@$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) M=$(PWD) DRIVER_VERSION="$(DRIVER_VERSION)" modules

clean:
	@$(MAKE) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) -C $(KROOT) M=$(PWD) clean
