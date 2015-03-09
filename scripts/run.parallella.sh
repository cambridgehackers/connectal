#
# push programs to a parallella board
# running linux, and execute
set -x
set -e
export SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"
echo "run.parallella.sh parameters are:" $*
bitfile=$1
ubuntuexe=$2
parallellahost=$3
if [ "$RUNTIMELIMIT" != "" ]; then
    TIMELIMIT=$RUNTIMELIMIT
else
    TIMELIMIT=180
fi
exename=`basename $ubuntuexe`
for f in $RUNFILES; do
    scp $f $parallellahost:/mnt/sdcard/tmp
done
scp $bitfile $parallellahost:/tmp
scp $ubuntuexe $parallellahost:/tmp
scp $CONNECTALDIR/drivers/portalmem/portalmem.ko $parallellahost:/tmp
scp $CONNECTALDIR/drivers/zynqportal/zynqportal.ko $parallellahost:/tmp
set +e
ssh $parallellahost sudo rmmod portalmem
ssh $parallellahost sudo rmmod zynqportal
set -e
ssh $parallellahost sudo insmod /tmp/portalmem.ko
ssh $parallellahost sudo insmod /tmp/zynqportal.ko
ssh $parallellahost sudo "gzip -dc /tmp/`basename $bitfile` >/dev/xdevcfg"
ssh $parallellahost sudo cat /dev/connectal

ssh $parallellahost sudo /tmp/$exename

status=0
if [ "$status" != "0" ]; then
  status=1
fi
exit $status
