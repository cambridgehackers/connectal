#!/usr/bin/env python3
# Copyright (c) 2013 Quanta Research Cambridge, Inc.
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use, copy,
# modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

from __future__ import print_function
import sys

print('dumptrace: opening', sys.argv[1])
lines =  open(sys.argv[1]).readlines()
print('len', len(lines))
addressarr = []
for thisline in lines:
    thisline = thisline.strip()
    if thisline.find(' ') >= 0 or thisline.startswith('http:'):
        continue
    #print('LL', thisline)
    addressarr.append(int(thisline, 16))
if addressarr.pop() != 0xaaaabbbb or addressarr.pop() != 0xdeadbeef:
    printf('dumptrace: incomplete read of trace data')
    sys.exit(1)
while len(addressarr) > 0 and addressarr[0] == 0xdeadbeef:
    #remove leading entries in case the trace buffer was never really full
    addressarr.pop(0)
for item in addressarr:
    transname = ['REQ ', 'REQR', '                   IND ', '                   INDR'];
    topbits = item >> 18
    fpganumber = (item >> 16) & 0x7
    transtype = (item >> 14) & 0x3
    channel = (item >> 8) & 0x3f
    bottombits = item & 0xff
    if topbits != 0x1b90:
        print('dumptrace: address is not in m_axi_gp[0] range', format(topbits, '05x'))
    fpganame = 'Dir  '
    channelname = '         '
    if fpganumber != 0:
        fpganame = 'fpga'+format(fpganumber, 'x')
        channelname = 'channel ' + format(channel, 'x')
    elif channel != 2:
        channelname = 'channel ' + format(channel, 'x')
    if bottombits & 0x3 != 0:
        print('dumptrace: LSB are not 32 word aligned')
    print(fpganame, transname[transtype], channelname, format(bottombits >> 2, '2x'))
