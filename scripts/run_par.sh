#/bin/bash
set -e
set -x
PROJNAME=hdmidisplay
PARTNAME=xc7z020clg484-1
ngdbuild -p $PARTNAME -nt timestamp -bm $PROJNAME.bmm $PROJNAME.ngc \
    -uc $PROJNAME.ucf $PROJNAME.ngd
map -o ${PROJNAME}_map.ncd -w -pr b -ol high -timing -detail $PROJNAME.ngd \
    $PROJNAME.pcf
par -w -ol high ${PROJNAME}_map.ncd $PROJNAME.ncd $PROJNAME.pcf
trce -e 3 -xml $PROJNAME.twx $PROJNAME.ncd $PROJNAME.pcf
