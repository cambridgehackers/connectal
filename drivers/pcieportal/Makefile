VERSION=140520.1

# On Centos: sudo yum install kernel-headers

obj-m += pcieportal.o

KVERSION=$(shell uname -r)
export KROOT=/lib/modules/$(KVERSION)/build
export BS_MOD_DIR=$(DESTDIR)/lib/modules/$(KVERSION)/connectal

.PHONY: default
default: pcieportal.ko ../portalmem/portalmem.ko

EXTRA_CFLAGS = -I$(PWD) -I$(PWD)/../../cpp -I$(PWD)/../.. -I$(PWD)/../portalmem -I$(PWD)/../../generated/cpp
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
ifeq ("$(DESTDIR)", "")
	depmod
endif

.PHONY: uninstall
uninstall:
	rm -f $(BS_MOD_DIR)/pcieportal.ko
	rmdir --ignore-fail-on-non-empty $(BS_MOD_DIR)
ifeq ("$(DESTDIR)", "")
	depmod
endif

.PHONY: clean
clean:
	rm -rf *.ko *.o *.mod.*
	rm -rf Module.symvers Module.markers modules.order
	cd ../portalmem; make -f Makefile.x86 clean

.PHONY: rmmod
rmmod:
	rmmod portalmem || true
	rmmod pcieportal || true

.PHONY: insmod
insmod: rmmod
	insmod pcieportal.ko
	-chmod agu+rw /dev/portal*
	insmod ../portalmem/portalmem.ko
	chmod agu+rw /dev/portalmem

.PHONY: install-dkms
install-dkms:
	mkdir -p $(DESTDIR)//usr/src/connectal-$(VERSION)
	sed "s/@VERSION@/$(VERSION)/" dkms.conf > dkms.conf.out
	cp -fv dkms.conf.out $(DESTDIR)/usr/src/connectal-$(VERSION)/dkms.conf
	cp -fv pcieportal.c pcieportal.h $(DESTDIR)/usr/src/connectal-$(VERSION)
	cp -fv ../../cpp/*.[ch] ../portalmem/*.[ch] \
	../../generated/cpp/*.[ch] \
	$(DESTDIR)/usr/src/connectal-$(VERSION)
	sed -i 's|drivers/portalmem/||' $(DESTDIR)/usr/src/connectal-$(VERSION)/*.[ch]
	sed -i 's|drivers/pcieportal/||' $(DESTDIR)/usr/src/connectal-$(VERSION)/*.[ch]
	sed -i 's|drivers/zynqportal/||' $(DESTDIR)/usr/src/connectal-$(VERSION)/*.[ch]
	sed -i 's|../../cpp/||g' $(DESTDIR)/usr/src/connectal-$(VERSION)/*.[ch]
	grep drivers $(DESTDIR)/usr/src/connectal-$(VERSION)/
	cp -fv Makefile.dkms $(DESTDIR)/usr/src/connectal-$(VERSION)/Makefile
