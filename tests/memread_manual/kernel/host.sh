#/bin/bash
set -x
set -e
gcc -o bsim_relay -g -I../../../cpp ../../../cpp/bsim_relay.c ../../../cpp/sock_utils.c -lpthread
