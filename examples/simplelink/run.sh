#!/bin/sh

cd bluesim

BLUESIM_SOCKET_NAME=socket1 ./bin/bsim & bsim1_pid=$!
BLUESIM_SOCKET_NAME=socket2 ./bin/bsim & bsim2_pid=$!

BLUESIM_SOCKET_NAME=socket1 ./bin/bsim_exe & bsimexe1_pid=$!
BLUESIM_SOCKET_NAME=socket2 ./bin/bsim_exe & bsimexe2_pid=$!

wait $bsimexe1_pid $bsimexe2_pid
kill $bsim1_pid $bsim2_pid
