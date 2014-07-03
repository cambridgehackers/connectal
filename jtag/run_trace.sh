#/bin/bash
set -x
set -e
openocd -f zedtrace.cfg 2>trace.xx.tempfile
sed -e"s/\(.\)\(...\)\(....\)/\1 \2 \3 /" <trace.xx.tempfile  \
| sed -e"s/^0/0 0/" -e"s/^1/0 1/" -e"s/^2/1 0/" -e"s/^3/1 1/" \
      -e"s/^4/2 0/" -e"s/^5/2 1/" -e"s/^6/3 0/" -e"s/^7/3 1/" \
      -e"s/^8/4 0/" -e"s/^9/4 1/" -e"s/^A/5 0/" -e"s/^B/5 1/" >trace.log
#rm -f trace.xx.tempfile
