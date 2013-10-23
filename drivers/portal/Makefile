obj-m += portal.o

export KROOT=/scratch/mdk/device_xilinx_kernel/

portal.ko: portal.h portal.c
	@$(MAKE) ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- -C $(KROOT) xilinx_zynq_portal_defconfig  
	@$(MAKE) ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- -C $(KROOT) oldconfig
	@$(MAKE) -j 8 ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- -C $(KROOT) zImage
	@$(MAKE) ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- -C $(KROOT) M=$(PWD) modules 
	cp portal.ko ~/adb_scripts/

clean:
	@$(MAKE) ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- -C $(KROOT) M=$(PWD) clean
