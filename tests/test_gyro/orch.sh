#!/bin/bash

#make build.bluesim
cp bluesim/bin/connectal.so .
./sample.py &
sleep 2
make run.bluesim