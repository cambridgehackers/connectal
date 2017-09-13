#!/bin/bash

HERE=$PWD
cd ../..
export CL_DIR=`pwd`
cd $HERE

pushd ~/aws-fpga
source ./hdk_setup.sh
popd


~/aws-fpga/hdk/cl/examples/cl_hello_world/build/scripts/aws_build_dcp_from_cl.sh -ignore_memory_requirement -notify
