#! /usr/bin/env python3
# Copyright (c) 2014 Quanta Research Cambridge, Inc
# Original author John Ankcorn
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

# This is a control program for and NP-02B ethernet power switch from synaccess-net.com.
#
# The API is documented at:
#    http://www.synaccess-net.com/downloadDoc/NPStartup-B.pdf
#

from __future__ import print_function
import socket,sys,time

if sys.argv[1] == 'discover':
    import discover_tcp
    discover_tcp.detect_network(None,23,False)
    sys.exit(0)

if len(sys.argv) < 3:
    print('power.py <ipaddress> <command> ...')
    print('Where <command> is:')
    print('    pset n v    Sets outlet #n to v(value 1-on,0-off)')
    print('    mac         Displays Ethernet port Mac address')
    print('    nwshow      Displays network Status')
    print('    pshow       Displays outlet status')
    print('    sysshow     Displays system information')
    print('    time        Displays current time')
    print('    ver         Displays hardware and software versions')
    sys.exit(1)

lines = []
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((sys.argv[1], 23))
inline = ''
for item in sys.argv[2:]:
    inline = inline + item + ' '
s.send(inline + '\r\nlogout\r\n')
inline = ''
while True:
    data = s.recv(1000)
    if not data:
        break
    for c in data:
        if c == '\r' or c == '\n':
            if inline != '':
                print(inline)
            inline = ''
        else:
            inline = inline + c
s.close()
if inline != '':
    print(inline)
print('connection ended')
