obj-m += pcie-portal.o portalalloc.o

export KROOT=/lib/modules/$(shell uname -r)/build
export BS_MOD_DIR=/lib/modules/$(shell uname -r)/bluespec
export UDEV_RULES_DIR=/etc/udev/rules.d

.PHONY: default
default: pcie-portal.ko portalalloc.ko

EXTRA_CFLAGS = -I$(PWD)
cflags-y += -I$(PWD)
pcie-portal-y = bluenoc.o dma-buf.o

portalalloc.o: ../../drivers/alloc/portalalloc.c ../../drivers/alloc/portalalloc.h

pcie-portal.ko: bluenoc.c bluenoc.h ../../drivers/alloc/portalalloc.h dma-buf.c
	@$(MAKE) -C $(KROOT) M=$(PWD) modules

portalalloc.ko: portalalloc.c ../../drivers/alloc/portalalloc.h
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

.PHONY: insmod
insmod:
	sudo rmmod portalalloc || true
	sudo rmmod pcie-portal || true
	sudo insmod pcie-portal.ko
	sudo insmod portalalloc.ko
