#!/bin/sh

cd xsim

SOFTWARE_SOCKET_NAME=node1. xsim -R work.xsimtop  & xsim1_pid=$!
SOFTWARE_SOCKET_NAME=node2. xsim -R work.xsimtop & xsim2_pid=$!

sleep 10

SOFTWARE_SOCKET_NAME=node1. ./bin/ubuntu.exe & xsimexe1_pid=$!
SOFTWARE_SOCKET_NAME=node2. ./bin/ubuntu.exe & xsimexe2_pid=$!

wait $xsimexe1_pid $xsimexe2_pid
kill $xsim1_pid $xsim2_pid
