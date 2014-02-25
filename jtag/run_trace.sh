#/bin/bash
set -x
set -e
openocd -f zedtrace.cfg 2>trace.xx
