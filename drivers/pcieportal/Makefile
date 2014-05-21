VERSION=140520.1

# On Centos: sudo yum install kernel-headers

obj-m += pcieportal.o

export KROOT=/lib/modules/$(shell uname -r)/build
export BS_MOD_DIR=/lib/modules/$(shell uname -r)/bluespec
export UDEV_RULES_DIR=/etc/udev/rules.d

.PHONY: default
default: pcieportal.ko ../portalmem/portalmem.ko

EXTRA_CFLAGS = -I$(PWD)
cflags-y += -I$(PWD)

../portalmem/portalmem.ko: ../portalmem/portalmem.c
	cd ../portalmem; make -f Makefile.x86

pcieportal.ko: pcieportal.c pcieportal.h
	@$(MAKE) -C $(KROOT) M=$(PWD) modules

.PHONY: modules_check
modules_check:
	@$(MAKE) -C $(KROOT) C=2 M=$(PWD) modules

.PHONY: install
install: pcieportal.ko
	install -d -m755 $(BS_MOD_DIR)
	install -m644 pcieportal.ko $(BS_MOD_DIR)
	install -m644 ../portalmem/portalmem.ko $(BS_MOD_DIR)
	depmod
	install -m644 99-pcieportal.rules $(UDEV_RULES_DIR)

.PHONY: uninstall
uninstall:
	rm -f $(BS_MOD_DIR)/pcieportal.ko
	rmdir --ignore-fail-on-non-empty $(BS_MOD_DIR)
	depmod
	rm -f $(UDEV_RULES_DIR)/99-pcieportal.rules

.PHONY: clean
clean:
	rm -rf *.ko *.o *.mod.*
	rm -rf Module.symvers Module.markers modules.order

.PHONY: rmmod
rmmod:
	rmmod portalmem || true
	rmmod pcieportal || true

.PHONY: insmod
insmod: rmmod
	insmod pcieportal.ko
	-chmod agu+rw /dev/fpga*
	insmod ../portalmem/portalmem.ko
	chmod agu+rw /dev/portalmem

.PHONY: install-dkms
install-dkms:
	mkdir -p /usr/src/pcieportal-$(VERSION)
	cp -fv pcieportal.c pcieportal.h dkms.conf /usr/src/pcieportal-$(VERSION)
	cp -fv ../portalmem/portalmem.h ../portalmem/portalmem.c /usr/src/pcieportal-$(VERSION)
	cp -fv Makefile.dkms /usr/src/pcieportal-$(VERSION)/Makefile
