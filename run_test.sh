#
set -e 
set -x
python yapps/yapps2.py syntax.g
chmod a+x syntax.py
ls ../blue-projects/80211/*.bsv | while read filename ; do
    echo $filename
    ./syntax.py $filename
done
