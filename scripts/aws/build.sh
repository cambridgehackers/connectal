#!/bin/bash

export CONNECTALDIR=~/connectal
echo "CONNECTALDIR=$CONNECTALDIR"

SCRIPTSDIR=`pwd`
echo SCRIPTSDIR=$SCRIPTSDIR
if [ `basename $SCRIPTSDIR` = 'scripts' ]; then
  cd ../..
else
  mkdir -p design
  mkdir -p build/checkpoints/to_aws
  mkdir -p build/constraints
  mkdir -p build/reports
  mkdir -p build/scripts
  mkdir -p build/src_post_encryption
  SCRIPTSDIR=`pwd`/build/scripts
  echo SCRIPTSDIR=$SCRIPTSDIR
fi

rsync -v $CONNECTALDIR/scripts/aws/* $SCRIPTSDIR

export CL_DIR=`pwd`
cd $SCRIPTSDIR

cp -fv $CONNECTALDIR/verilog/cl_id_defines.vh $SCRIPTSDIR/../../design

pushd ~/aws-fpga
source ./hdk_setup.sh
popd

echo '#placeholder' > ../constraints/cl_pnr_user.xdc
echo '#placeholder' > ../constraints/cl_synth_user.xdc

~/aws-fpga/hdk/cl/examples/cl_hello_world/build/scripts/aws_build_dcp_from_cl.sh -ignore_memory_requirement -notify
