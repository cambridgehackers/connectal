#
set -e 
#set -x
#python yapps/yapps2.py --dump syntax.g
python yapps/yapps2.py syntax.g
chmod a+x syntax.py

if [ "$1" != "" ] ; then
    echo running one $1
    ./syntax.py $1 $2
exit 1
fi
#ls ../blue-projects/80211/*.bsv 
#find ../blue-projects/ -name \*.bsv 
cat xx.bad \
| while read filename ; do
    echo $filename
    BNAME=`basename $filename`
    if [ "$BNAME" == "Preambles.bsv" ] ; then
        echo "dont try: recursion depth"
    elif [ "$BNAME" == "NewLutInv.bsv" ] ; then
        echo "dont try: recursion depth"
    elif [ "$BNAME" == "WiMAXPreambles.bsv" ] ; then
        echo "dont try: recursion depth"
    elif [ "$BNAME" == "WiFiPreambles.bsv" ] ; then
        echo "dont try: recursion depth"
    else
        ./syntax.py $filename
    fi
done
