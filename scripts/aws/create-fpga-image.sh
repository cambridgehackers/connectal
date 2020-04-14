#!/bin/bash

name=$1
timestamp=$2

if [ "$name" == "" -o "$timestamp" == "" ]; then
    echo "usage: $0 <name> <timestamp>" >&2
    exit -1
fi

if [ -d "build/checkpoints" ]; then
    CHECKPOINTS_DIR="build/checkpoints"
fi
if [ -d "awsf1/build/checkpoints" ]; then
    CHECKPOINTS_DIR="awsf1/build/checkpoints"
fi

aws s3 cp $CHECKPOINTS_DIR/to_aws/$timestamp.Developer_CL.tar s3://aws-fpga/$name/
aws s3 cp $CHECKPOINTS_DIR/$timestamp.debug_probes.ltx s3://aws-fpga/$name/
aws ec2 create-fpga-image --name $name --description $timestamp --input-storage-location Bucket=aws-fpga,Key=$name/$timestamp.Developer_CL.tar --logs-storage-location Bucket=aws-fpga,Key=logs-folder | tee latest-fpga-image.json
