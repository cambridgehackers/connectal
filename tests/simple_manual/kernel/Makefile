
BOARD=kc705

export KROOT=/lib/modules/$(shell uname -r)/build
CPPDIR=../../../cpp
BOARDDIR=../$(BOARD)/jni

testme-y := ../simple_manual.o \
     $(BOARDDIR)/SimpleIndicationWrapper.o \
     $(BOARDDIR)/SimpleRequestProxy.o \
     $(CPPDIR)/portal.o \

#     $(CPPDIR)/dmaManager.o

obj-m := testme.o

ccflags-y := -I$(src)/.. -I$(src)/$(CPPDIR) -I$(src)/$(BOARDDIR) -DMMAP_HW

default:
	$(MAKE) -C $(KROOT) M=$(PWD) modules

clean:
	$(MAKE) -C $(KROOT) M=$(PWD) clean
	rm -f a.out

