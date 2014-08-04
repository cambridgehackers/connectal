#!/bin/sh

#cd `dirname $0`

BOARD=`basename $PWD`
echo BOARD=$BOARD

BUILD_DIR=build

SCRIPTDIR=`dirname $0`
echo $SCRIPTDIR
DBNDIR=`cd $SCRIPTDIR/..; /bin/pwd`
XBSVDIR=`cd $SCRIPTDIR/../../xbsv; /bin/pwd`
pwd
echo DBNDIR=$DBNDIR
opencv_android=$DBNDIR/../opencv/platforms/android
opencv_build_dir=$DBNDIR/../opencv/build

export ANDROID_NDK=/scratch/android-ndk-r9d

mkdir -p $BUILD_DIR
cd $BUILD_DIR


RUN_CMAKE="cmake -DOpenCV_DIR=$opencv_build_dir -DCMAKE_TOOLCHAIN_FILE=$opencv_android/android.toolchain.cmake -DANDROID_ABI=armeabi-v7a -DANDROID_NATIVE_API_LEVEL=19 -DBOARD=$BOARD -DXBSVDIR=$XBSVDIR -DDBNDIR=$DBNDIR ../.. "
echo $RUN_CMAKE
$RUN_CMAKE
