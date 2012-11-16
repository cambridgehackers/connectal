#
set -e 
set -x
#python yapps/yapps2.py --dump syntax.g
python yapps/yapps2.py syntax.g
chmod a+x syntax.py
#./syntax.py  ../blue-projects/80211/Interleaver.bsv
#exit 1
ls ../blue-projects/80211/*.bsv | while read filename ; do
    echo $filename
    ./syntax.py $filename
done
