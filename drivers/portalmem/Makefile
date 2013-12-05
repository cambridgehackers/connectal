obj-m += portalmem.o

export KROOT=$(DEVICE_XILINX_KERNEL)

default: portalmem.ko
	cp portalmem.ko ~/adb_scripts/

portalmem.ko: portalmem.h portalmem.c
	@$(MAKE) ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- -C $(KROOT) xilinx_zynq_portal_defconfig  
	@$(MAKE) ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- -C $(KROOT) oldconfig
	@$(MAKE) -j 8 ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- -C $(KROOT) zImage
	@$(MAKE) ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- -C $(KROOT) M=$(PWD) modules  

clean:
	@$(MAKE) ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- -C $(KROOT) M=$(PWD) clean
