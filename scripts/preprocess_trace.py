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

from __future__ import print_function
import sys

print('preprocess_trace.py:', sys.argv)
cppind = []
bsvind = []
for filename in sys.argv[2:]:
    data = open(filename).readlines()
    hasdisplay = False
    hasdispind = False
    for line in data:
        if line.find('$display') >= 0:
            hasdisplay = True
        if line.find('printfInd') >= 0:
            hasdispind = True
    if hasdisplay and hasdispind:
        fname = sys.argv[1] + '/generatedbsv/' + filename
        fh = open(fname, 'w')
        for line in data:
            ind = line.find('$display')
            if ind >= 0:
                param = line[ind+8:].strip()[1:][:-2].strip()
                formatstr = ''
                pitem = ''
                level = 0
                informat = True
                pactual = []
                for ch in param[1:]:
                    if informat:
                        if ch == '"':
                            if level == 0:
                                informat = False
                        else:
                            formatstr = formatstr + ch
                    elif ch == ',':
                        if pitem != '':
                            pactual.append(pitem.strip())
                        pitem = ''
                    else:
                        pitem = pitem + ch
                pactual.append(pitem.strip())
                freplace = 'printfind_'
                lastch = ''
                plist = []
                for ch in formatstr:
                    if lastch == '%':
                        if ch == 'x':
                            plist.append('Bit#(32)')
                        else:
                            print('unknown format char', ch)
                    if ch == '-':
                        freplace = freplace + '__'
                    elif (ch >= 'A' and ch <= 'Z') or (ch >= 'a' and ch <= 'z') or (ch >= '0' and ch <= '9'):
                        freplace = freplace + ch
                    else:
                        freplace = freplace + '_' + '{:02x}'.format(ord(ch))
                    lastch = ch
                line = line[:ind] + 'printfInd.' + freplace + '(' + ','.join(pactual) + ');\n'
                pformal = ''
                pactual = ''
                pbsv = ''
                pcount = 1
                for item in plist:
                    if pcount > 1:
                        pformal = pformal + ', '
                        pactual = pactual + ', '
                        pbsv = pbsv + ', '
                    pvar = 'v%d' % pcount
                    pcount = pcount + 1
                    if item == 'Bit#(32)':
                        pformal = pformal + 'uint32_t ' + pvar
                        pactual = pactual + pvar
                    pbsv = pbsv + item + ' ' + pvar
                cppind.append('    void ' + freplace + '(' + pformal + ') { printf("' + formatstr + '\\n", ' + pactual + '); }\n')
                bsvind.append('    method Action ' + freplace + '(' + pbsv + ');\n')
            fh.write(line)
        fh.close()
if cppind != []:
    fname = sys.argv[1] + '/jni/printfInd.h'
    fh = open(fname, 'w')
    fh.write('class DisplayInd : public DisplayIndWrapper\n')
    fh.write('{\n')
    fh.write('public:\n')
    fh.write('    DisplayInd(unsigned int id, PortalPoller *poller) : DisplayIndWrapper(id, poller) {}\n')
    for item in cppind:
        fh.write(item)
    fh.write('};\n')
    fh.close()
if bsvind != []:
    fname = sys.argv[1] + '/generatedbsv/DisplayInd.bsv'
    fh = open(fname, 'w')
    fh.write('interface DisplayInd;\n')
    for item in bsvind:
        fh.write(item)
    fh.write('endinterface\n')
    fh.close()
sys.exit(0)
