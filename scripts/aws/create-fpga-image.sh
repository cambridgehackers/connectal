#!/bin/sh

name=$1
timestamp=$2

if [ "$name" == "" -o "$timestamp" == "" ]; then
    echo usage: $0 <name> <timestamp> >&2
    exit -1
fi

aws s3 cp awsf1/build/checkpoints/to_aws/$timestamp.Developer_CL.tar s3://aws-fpga/$name/
aws s3 cp awsf1/build/checkpoints/$timestamp.debug_probes.ltx s3://aws-fpga/$name/
ec2 create-fpga-image --name $name --description $timestamp --input-storage-location Bucket=aws-fpga,Key=$name/$timestamp.Developer_CL.tar --logs-storage-location Bucket=aws-fpga,Key=logs-folder > latest-fpga-image.json
