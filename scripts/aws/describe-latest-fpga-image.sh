#!/bin/bash

if [ -f latest-fpga-image.json ]; then
    aws ec2 describe-fpga-images --fpga-image-ids `jq -r .FpgaImageId < latest-fpga-image.json`
fi

