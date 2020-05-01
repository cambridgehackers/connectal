#!/bin/bash

scriptname=`which $0`
scriptdir=`dirname $scriptname`
scriptdir=`dirname $scriptdir`
export CONNECTALDIR=`dirname $scriptdir`
echo "CONNECTALDIR=$CONNECTALDIR"

if [ "$AWS_FPGA_BUCKET" == "" ]; then
    AWS_FPGA_BUCKET=aws-fpga
fi

if [ "$AWS_FPGA_REPO_DIR" == "" ]; then
    if [ -d `dirname $CONNECTALDIR`/aws-fpga ]; then
	pushd `dirname $CONNECTALDIR`/aws-fpga
	. hdk_setup.sh
	popd
    fi
    if [ -d ~/aws-fpga ]; then
	pushd ~/aws-fpga
	. hdk_setup.sh
	popd
    fi
fi

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

## copy the scripts into the build directory so we don't have to worry about paths
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

echo '#placeholder' > ../constraints/cl_pnr_user.xdc
echo '#placeholder' > ../constraints/cl_synth_user.xdc

## run Vivado to build the FPGA image
$AWS_FPGA_REPO_DIR/hdk/common/shell_stable/build/scripts/aws_build_dcp_from_cl.sh -ignore_memory_requirement -notify -foreground

PROJECT_DIR=`dirname $CL_DIR`
PROJECT_NAME=`basename $PROJECT_DIR`
echo PROJECT_NAME=${PROJECT_NAME}

## return to $CL_DIR
cd $CL_DIR
## and now should be in awsf1 subdirectory of $PROJECT_DIR
pwd

last_log=`realpath build/scripts/last_log`
echo last_log=${last_log}
build_timestamp=`basename ${last_log} .vivado.log`
echo build_timestamp=${build_timestamp}

##
## if build completed successfully, request AWS to create an FPGA image
##
if [ -f build/checkpoints/to_aws/${build_timestamp}.Developer_CL.tar ]; then
    ## request AWS to create an AWS FPGA image
    $CONNECTALDIR/scripts/aws/create-fpga-image.sh $PROJECT_NAME $build_timestamp $AWS_FPGA_BUCKET \
	&& ( sleep 1; 
	     ## query AWS to make sure the FPGA image is building
	     $CONNECTALDIR/scripts/aws/describe-latest-fpga-image.sh )
fi

if [ "$EMAIL" != "" ]; then
    echo "Connectal AWS FPGA: - Calling notification script to send e-mail to $EMAIL";
    ${CONNECTALDIR}/scripts/aws/notify_via_sns.py --build-project ${PROJECT_NAME} --filename ${filename} --timestamp ${build_timestamp} --fpga-image-ids `cat latest-fpga-image.json`
fi

