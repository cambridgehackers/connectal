#/bin/bash
set -x
set -e
gcc -o bsimhost -g -I../../../cpp bsimhost.c ../../../cpp/sock_utils.c -lpthread
