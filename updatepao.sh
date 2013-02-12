#!/bin/sh

vinput=$1
shift
pao=$1
shift

vdirs="$BLUESPECDIR/Verilog $*"

echo vinput $vinput
echo pao $pao
echo vdirs $vdirs

destdir=`dirname $1`

vfiles=`grep '#(' $vinput | sed 's/#(.*//' | sort | uniq`
for v in $vfiles; do
    if [ -f $destdir/$v.v ]; then
        ls -l $destdir/$v.v
        continue
    fi
    for vdir in $vdirs; do
        if [ -f $vdir/$v.v ] ; then 
            cp -v $vdir/$v.v $destdir
            libname=`tail -1 $pao | cut -d ' ' -f 2`
            echo "lib $libname $v verilog"
            echo "lib $libname $v verilog" >> $pao
        fi
    done
done
