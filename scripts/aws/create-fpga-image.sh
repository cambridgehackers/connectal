#!/bin/bash

name=$1
timestamp=$2
bucket="aws-fpga"

if [ "$AWS_FPGA_BUCKET" != "" ]; then
    bucket="$AWS_FPGA_BUCKET"
fi

if [ "$name" == "" -o "$timestamp" == "" ]; then
    echo "usage: $0 <name> <timestamp> [s3 bucket]" >&2
    exit -1
fi

if [ "$3" != "" ]; then
    bucket="$3"
fi

if [ -d "build/checkpoints" ]; then
    CHECKPOINTS_DIR="build/checkpoints"
fi
if [ -d "awsf1/build/checkpoints" ]; then
    CHECKPOINTS_DIR="awsf1/build/checkpoints"
fi

aws s3 cp $CHECKPOINTS_DIR/to_aws/$timestamp.Developer_CL.tar s3://$bucket/$name/
aws s3 cp $CHECKPOINTS_DIR/$timestamp.debug_probes.ltx s3://$bucket/$name/
aws ec2 create-fpga-image --name $name --description $timestamp --input-storage-location Bucket=$bucket,Key=$name/$timestamp.Developer_CL.tar --logs-storage-location Bucket=$bucket,Key=logs-folder | tee latest-fpga-image.json
