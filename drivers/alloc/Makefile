obj-m += portalalloc.o

export KROOT=$(DEVICE_XILINX_KERNEL)

default: portalalloc.ko
	cp portalalloc.ko ~/adb_scripts/

portalalloc.ko: portalalloc.h portalalloc.c
	@$(MAKE) ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- -C $(KROOT) xilinx_zynq_portal_defconfig  
	@$(MAKE) ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- -C $(KROOT) oldconfig
	@$(MAKE) -j 8 ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- -C $(KROOT) zImage
	@$(MAKE) ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- -C $(KROOT) M=$(PWD) modules  

clean:
	@$(MAKE) ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- -C $(KROOT) M=$(PWD) clean
