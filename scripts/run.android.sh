#
set -x
set -e
export SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"
echo "run.android parameters are:" $*
androidexe=$1
if [ "$BUILDBOT_URL" == "" ]; then
   BUILDBOT_URL="http://sj9.qrclab.com/archive"
fi
if [ "$BUILDBOT_BUILD" != "" ]; then
   mkdir -p zedboard/bin
   (cd zedboard/bin; \
   curl -v -O $BUILDBOT_URL/$BUILDBOT_BUILD/bin/android.exe ; \
   curl -v -O $BUILDBOT_URL/$BUILDBOT_BUILD/bin/mkTop.xdevcfg.bin.gz)
   chmod agu+rx zedboard/bin/android.exe
   androidexe=zedboard/bin/android.exe
fi
if [ "$RUNPARAM" != "" ]; then
    ZEDBOARD_IPADDR=$RUNPARAM
else
    ZEDBOARD_IPADDR=`checkip`
fi
if [ "$RUNTIMELIMIT" != "" ]; then
    TIMELIMIT=$RUNTIMELIMIT
else
    TIMELIMIT=180
fi
ANDROID_SERIAL=$ZEDBOARD_IPADDR:5555
exename=`basename $androidexe`
adb -s $ANDROID_SERIAL disconnect $ZEDBOARD_IPADDR
sleep 2
adb connect $ZEDBOARD_IPADDR
adb -s $ANDROID_SERIAL root
sleep 2
adb connect $ZEDBOARD_IPADDR
## sometimes /mnt/sdcard is readonly:
adb -s $ANDROID_SERIAL shell mount -o remount,rw /mnt/sdcard
adb -s $ANDROID_SERIAL shell mkdir -p /mnt/sdcard/tmp
adb -s $ANDROID_SERIAL shell mount -t tmpfs tmpfs /mnt/sdcard/tmp
adb -s $ANDROID_SERIAL push $androidexe /mnt/sdcard/tmp
for f in $RUNFILES; do
    adb -s $ANDROID_SERIAL push $f /mnt/sdcard/tmp
done
adb -s $ANDROID_SERIAL shell rmmod portalmem
adb -s $ANDROID_SERIAL shell rmmod zynqportal
adb -s $ANDROID_SERIAL shell insmod /mnt/sdcard/portalmem.ko
adb -s $ANDROID_SERIAL shell insmod /mnt/sdcard/zynqportal.ko
adb -s $ANDROID_SERIAL shell "pwd"
adb -s $ANDROID_SERIAL shell touch /mnt/sdcard/tmp/perf.monkit
if [ "$CONNECTAL_DEBUG" != "" ]; then
adb -s $ANDROID_SERIAL forward tcp:5039 tcp:5039   
adb -s $ANDROID_SERIAL shell gdbserver :5039 /mnt/sdcard/tmp/android.exe &
TEMP=`dirname $androidexe`/../..
TEMPDIR=$TEMP/obj/local/armeabi
TEMPSCRIPT=$TEMP/xxfoo
echo set solib-search-path $TEMPDIR >$TEMPSCRIPT
echo target remote :5039 >>$TEMPSCRIPT
`ndk-which gdb` --command=$TEMPSCRIPT $TEMPDIR/android.exe
else
adb -s $ANDROID_SERIAL shell "cd /mnt/sdcard/tmp/; rm -f /mnt/sdcard/tmp/exit.status; /mnt/sdcard/timelimit -t $TIMELIMIT ./$exename $3; echo \$? > /mnt/sdcard/tmp/exit.status"
adb -s $ANDROID_SERIAL pull /mnt/sdcard/tmp/exit.status ./
adb -s $ANDROID_SERIAL pull /mnt/sdcard/tmp/perf.monkit `dirname $androidexe`
fi
adb -s $ANDROID_SERIAL shell rm -f /mnt/sdcard/tmp/`basename $androidexe` /mnt/sdcard/tmp/perf.monkit
pwd
status=`cat exit.status`
if [ "$status" != "0" ]; then
  status=1
fi
exit $status
