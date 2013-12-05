obj-m += pcie-portal.o

export KROOT=/lib/modules/$(shell uname -r)/build
export BS_MOD_DIR=/lib/modules/$(shell uname -r)/bluespec
export UDEV_RULES_DIR=/etc/udev/rules.d

.PHONY: default
default: pcie-portal.ko 

EXTRA_CFLAGS = -I$(PWD)
cflags-y += -I$(PWD)
#pcie-portal-y = pcieportal.o dma-buf.o
pcie-portal-y = pcieportal.o

pcie-portal.ko: pcieportal.c bluenoc.h dma-buf.c
	@$(MAKE) -C $(KROOT) M=$(PWD) modules

.PHONY: modules_check
modules_check:
	@$(MAKE) -C $(KROOT) C=2 M=$(PWD) modules

.PHONY: install
install: pcie-portal.ko
	install -d -m755 $(BS_MOD_DIR)
	install -m644 pcie-portal.ko $(BS_MOD_DIR)
	depmod
	install -m644 99-bluespec.rules $(UDEV_RULES_DIR)

.PHONY: uninstall
uninstall:
	rm -f $(BS_MOD_DIR)/pcie-portal.ko
	rmdir --ignore-fail-on-non-empty $(BS_MOD_DIR)
	depmod
	rm -f $(UDEV_RULES_DIR)/99-bluespec.rules

.PHONY: clean
clean:
	rm -rf *.ko *.o *.mod.*
	rm -rf Module.symvers Module.markers modules.order

.PHONY: rmmod
rmmod:
	sudo rmmod portalmem || true
	sudo rmmod pcie-portal || true

.PHONY: insmod
insmod: rmmod
	sudo insmod pcie-portal.ko
	sudo insmod portalmem.ko
	sudo chmod agu+rw /dev/fpga* /dev/portalmem
