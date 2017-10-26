#!/bin/bash

scriptname=`which $0`
scriptdir=`dirname $scriptname`
scriptdir=`dirname $scriptdir`
export CONNECTALDIR=`dirname $scriptdir`
echo "CONNECTALDIR=$CONNECTALDIR"

BUILD_DIR=`pwd`
echo BUILD_DIR=$BUILD_DIR
if [ `basename $BUILD_DIR` = 'scripts' ]; then
  cd ../..
else
  mkdir -p design
  mkdir -p build/checkpoints/to_aws
  mkdir -p build/constraints
  mkdir -p build/reports
  mkdir -p build/scripts
  mkdir -p build/src_post_encryption
  BUILD_DIR=`pwd`/build/scripts
  echo BUILD_DIR=$BUILD_DIR
fi

rsync -v $CONNECTALDIR/scripts/aws/* $BUILD_DIR

if [ ! -f $CONNECTALDIR/out/awsf1/ila_connectal_1/ila_connectal_1.xci ]; then
    echo
    echo 'Generating Integrated Logic Analyzer core'
    echo
    vivado -mode batch -source $CONNECTALDIR/scripts/connectal-synth-ila.tcl
    echo 
    echo 'Finished generating Integrated Logic Analyzer core'
    echo
fi

export CL_DIR=`pwd`
cd $BUILD_DIR
echo CL_DIR=$CL_DIR
echo BUILD_DIR=$BUILD_DIR

cp -fv $CONNECTALDIR/verilog/cl_id_defines.vh $BUILD_DIR/../../design

pushd ~/aws-fpga
source ./hdk_setup.sh
popd

echo '#placeholder' > ../constraints/cl_pnr_user.xdc
echo '#placeholder' > ../constraints/cl_synth_user.xdc

~/aws-fpga/hdk/common/shell_stable/build/scripts/aws_build_dcp_from_cl.sh -ignore_memory_requirement -notify -foreground
