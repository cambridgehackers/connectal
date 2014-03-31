##
## Usage: make BOARD=[zedboard,zc702] ANDROID_TOP=/path/to/android
##

all: gralloc.portal.so

 ../examples/hdmidisplay/$(BOARD)/jni/HdmiControlRequestProxy.h: ../lib/bsv/HdmiDisplay.bsv
	(cd ..; make hdmidisplay.$(BOARD) verilog android_exe)
	cp -v ../examples/hdmidisplay/$(BOARD)/hw/*.bin* .

gralloc.portal.so: gralloc.cpp mapper.cpp Android.mk ../lib/bsv/HdmiDisplay.bsv ../examples/hdmidisplay/$(BOARD)/jni/HdmiControlRequestProxy.h
	pushd $(ANDROID_TOP); . ./build/envsetup.sh; lunch zedboard-userdebug; popd; TOP=$(ANDROID_TOP) mm showcommands
	cp -v $(ANDROID_TOP)/out/target/product/zedboard/system/lib/hw/gralloc.portal.so gralloc.portal.so
