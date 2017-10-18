#!/bin/bash

filename=$1
if [ "$filename" = "" ]; then
    echo Usage: $0 filename
    exit 1
fi

basename=`basename $filename .Developer_CL.tar`
echo "basename=$basename"

aws s3 cp ../checkpoints/to_aws/$filename s3://aws-fpga/simple/$filename
aws s3 cp ../checkpoints.$basename.debug_probes.ltx s3://aws-fpga/simple/$filename
aws ec2 create-fpga-image --name simple --description "$filename" --input-storage-location Bucket=aws-fpga,Key=simple/$filename --logs-storage-location Bucket=aws-fpga,Key=logs-folder
