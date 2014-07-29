#
set -e
set -x
./bin/bsim& bsimpid=$!
echo bsimpid $bsimpid
EXISTMOD=`lsmod | grep testme | true`
echo EXISTMOD
if [ "$EXISTMOD" != "" ]; then
   sudo rmmod testme
#else
#   echo EXISTMOD
fi
sudo insmod testme.ko
./bsimhost
kill $bsimpid
dmesg | tail -200
