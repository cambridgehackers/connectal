#
set -e 
#set -x
#python yapps/yapps2.py --dump syntax.g
python yapps/yapps2.py syntax.g
chmod a+x syntax.py

if [ "$1" != "" ] ; then
    echo running one $1
    ./syntax.py $1
exit 1
fi
#ls ../blue-projects/80211/*.bsv 
find ../blue-projects/ -name \*.bsv \
| while read filename ; do
    echo $filename
    if [ "$filename" == "../blue-projects//80211_merge/common/Preambles.bsv" ] ; then
        echo "dont try: recursion depth"
    elif [ "$filename" == "../blue-projects//memocodeDesignContest2009/src/core/NewLutInv.bsv" ] ; then
        echo "dont try: recursion depth"
    elif [ "$filename" == "../blue-projects//ofdm/src/scripts/WiMAXPreambles.bsv" ] ; then
        echo "dont try: recursion depth"
    elif [ "$filename" == "../blue-projects//ofdm/src/WiMAX/Preambles.bsv" ] ; then
        echo "dont try: recursion depth"
    else
        ./syntax.py $filename
    fi
done
