#
set -e
set -x
../bluesim/bin/bsim& bsimpid=$!
echo bsimpid $bsimpid
if [ "`lsmod | grep kernel_exe`" != "" ]; then
   sudo rmmod kernel_exe
else
   echo "HA"
fi
sudo insmod kernel_exe.ko
./bsim_relay
kill $bsimpid
dmesg | tail -200
