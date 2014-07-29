#
set -e
set -x
../bluesim/bin/bsim& bsimpid=$!
echo bsimpid $bsimpid
if [ "`lsmod | grep testme`" != "" ]; then
   sudo rmmod testme
else
   echo "HA"
fi
sudo insmod testme.ko
./bsimhost
kill $bsimpid
dmesg | tail -200
