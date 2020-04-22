#!/bin/bash

if [ -f awsf1/latest-fpga-image.json ]; then
    aws ec2 describe-fpga-images --fpga-image-ids `jq -r .FpgaImageId < awsf1/latest-fpga-image.json`
fi
if [ -f latest-fpga-image.json ]; then
    aws ec2 describe-fpga-images --fpga-image-ids `jq -r .FpgaImageId < latest-fpga-image.json`
fi

