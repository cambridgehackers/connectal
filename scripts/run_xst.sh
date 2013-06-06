#/bin/bash
#set -x
PROJNAME=$1
echo "xst_run.sh $PROJNAME"
DIRNAME="/scratch/jca/testing/xbsv/xpsproj"
XILDIRNAME="/scratch/Xilinx/14.3/ISE_DS/EDK/hw"
FNAME=""
MAXFANOUT=""
if test "$PROJNAME" == "hdmidisplay" ; then
    MAXFANOUT="-max_fanout 10000\n"
fi

if test "$PROJNAME" == "hdmidisplay_processing_system7_0_wrapper" ; then
    FNAME=$DIRNAME/pcores/qqprocessing_system7_v4_02_a/data/qqprocessing_system7_v2_1_0.pao
elif test "$PROJNAME" == "hdmidisplay_hdmidisplay_0_wrapper" ; then
    FNAME=$XILDIRNAME/XilinxProcessorIPLib/pcores/proc_common_v3_00_a/data/proc_common_v2_1_0.pao
    FNAME="$FNAME\n$DIRNAME/pcores/hdmidisplay_v1_00_a/data/hdmidisplay_v2_1_0.pao"
elif test "$PROJNAME" != "hdmidisplay" ; then
    FNAME=$DIRNAME/pcores/axi_passthrough_v1_06_a/data/axi_passthrough_v2_1_0.pao
fi
rm -f xx.prj
echo -e $FNAME | while read filename ; do
    grep -v "#" $filename | while read line ; do
        a=( $line )
        alen=${#a[@]}
        if test $alen == 4 ; then
            TNAME=`dirname $filename`/../hdl/${a[3]}/${a[2]}
            if test ${a[3]} == "verilog" ; then
                echo ${a[3]} ${a[1]} `readlink -m $TNAME.v` >>xx.prj
            elif test ${a[3]} == "vhdl" ; then
                echo ${a[3]} ${a[1]} `readlink -m $TNAME.vhd` >>xx.prj
            fi
        fi
    done
done
if test "$PROJNAME" == "hdmidisplay_hdmidisplay_0_wrapper" ; then
    echo "vhdl work ../hdl/$PROJNAME.vhd" >>xx.prj
else
    echo "verilog work ../hdl/$PROJNAME.v" >>xx.prj
fi

echo -e "set -tmpdir $DIRNAME/synthesis/xst_temp_dir/
run\n-opt_mode speed\n-netlist_hierarchy as_optimized\n-opt_level 1
-p xc7z020clg484-1\n-top ${PROJNAME}\n-ifmt MIXED\n-ifn xx.prj
-ofn ../implementation/${PROJNAME}.ngc
-hierarchy_separator /\n-iobuf NO\n${MAXFANOUT}-sd {../implementation}
-vlgincdir {\"$DIRNAME/pcores/\" \"$XILDIRNAME/XilinxBFMinterface/pcores/\" \"$XILDIRNAME/XilinxProcessorIPLib/pcores/\" }" >xx.tmp

