#! /usr/bin/env python
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
        print('IIII', fname)
        fn = open(fname, 'w')
        for line in data:
            ind = line.find('$display')
            if ind >= 0:
                print('DDDDD', ind, line)
                param = line[ind+8:].strip()[1:][:-2].strip()
                print('PPP', param)
                format = ''
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
                            format = format + ch
                    elif ch == ',':
                        if pitem != '':
                            pactual.append(pitem.strip())
                        pitem = ''
                    else:
                        pitem = pitem + ch
                pactual.append(pitem.strip())
                freplace = ''
                lastch = ''
                plist = []
                for ch in format:
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
                        i = ord(ch)
                        j = int(i / 10)
                        freplace = freplace + '_' + str(j) + str(i - 10 * j)
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
                print('FFF void ' + freplace + '(' + pformal + ') { printf("' + format + '\\n", ' + pactual + '); }')
                print('GGG method Action ' + freplace + '(' + pbsv + ');')
                print('RRR', line.strip())
            fn.write(line)
        fn.close()
sys.exit(1)
