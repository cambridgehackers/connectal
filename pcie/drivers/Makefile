obj-m += bluenoc.o

export KROOT=/lib/modules/$(shell uname -r)/build
export BS_MOD_DIR=/lib/modules/$(shell uname -r)/bluespec
export UDEV_RULES_DIR=/etc/udev/rules.d

.PHONY: default
default: bluenoc.ko

bluenoc.ko: bluenoc.c bluenoc.h
	@$(MAKE) -C $(KROOT) M=$(PWD) modules

.PHONY: modules_check
modules_check:
	@$(MAKE) -C $(KROOT) C=2 M=$(PWD) modules

.PHONY: install
install: bluenoc.ko
	install -d -m755 $(BS_MOD_DIR)
	install -m644 bluenoc.ko $(BS_MOD_DIR)
	depmod
	install -m644 99-bluespec.rules $(UDEV_RULES_DIR)

.PHONY: uninstall
uninstall:
	rm -f $(BS_MOD_DIR)/bluenoc.ko
	rmdir --ignore-fail-on-non-empty $(BS_MOD_DIR)
	depmod
	rm -f $(UDEV_RULES_DIR)/99-bluespec.rules

.PHONY: clean
clean:
	rm -rf bluenoc.ko bluenoc.o bluenoc.mod.*
	rm -rf Module.symvers Module.markers modules.order
