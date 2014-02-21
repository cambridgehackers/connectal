#
set -e
set -x
#openocd  -f digilent-hs1.cfg -f kc705.cfg 
openocd  -f digilent-hs2.cfg -f zedboard.cfg 
