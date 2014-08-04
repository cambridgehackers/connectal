#!/bin/sh

## run this in the opencv directory
OPENCV_DIR=$PWD

mkdir build; cd build

cmake -DCMAKE_TOOLCHAIN_FILE=$OPENCV_DIR/platforms/android/android.toolchain.cmake -DANDROID_STL=stlport_static -DANDROID_NATIVE_API_LEVEL=19 ..
make -j8
