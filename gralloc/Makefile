TOP=/scratch/jamey/xlaatu

all: gralloc.portal.so

gralloc.portal.so: gralloc.cpp mapper.cpp Android.mk ../lib/bsv/HdmiDisplay.bsv
	pushd $(TOP); . ./build/envsetup.sh; lunch zedboard-userdebug; popd; TOP=$(TOP) mm showcommands
	cp -v $(TOP)/out/target/product/zedboard/system/lib/hw/gralloc.portal.so gralloc.portal.so
