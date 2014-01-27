#!/usr/bin/python
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

def printval(starty, lasty, lastval):
    global outstring, lastx
    if starty != -1:
        lastval = lastval/ 3232.0 - 467
        if lasty < 100:
            lastval = lastval - 2566
            if lasty <= 35:
                lastval = lastval - 2566
        lastval = lastval - 36 * int((lastx - 14)/2)
        if lastx >= 32:
            lastval = lastval - 28
            if lastx >= 36:
                lastval = lastval - 28
                if lastx >= 50:
                    lastval = lastval - 30
                    if lastx >= 54:
                        lastval = lastval - 28
        outstring = outstring + ' %3d-%3d/%d' % (starty, lasty, lastval)

print('readll: opening', sys.argv[1])
lines =  open(sys.argv[1]).readlines()
print('len', len(lines))
i = 0
toplist = {}
topoffset = {}
topref = {}
for thisline in lines:
    if thisline[0] == ';':
        continue
    iteml = thisline.split()
    if iteml[0] != 'Bit' or not iteml[4].startswith('Block=SLICE_X'):
        print('Non-Bit line', thisline.strip())
        continue
    for i in range(3):
        iteml[i+1] = int(iteml[i+1], 0)
    bitoff = iteml[1]
    frameoffset = iteml[3]
    temp = iteml[4][13:]
    ind = temp.find('Y')
    coordx = int(temp[:ind])
    coordy = int(temp[ind+1:])
    itemtype = iteml[5]
    if itemtype.startswith('Ram='):
        continue
    if not itemtype.endswith('MUX'):
        itemtype = itemtype[:6] + '   ' + itemtype[6:]
    if not topoffset.get(itemtype):
        topoffset[itemtype] = {}
    if not topoffset[itemtype].get(frameoffset):
        topoffset[itemtype][frameoffset] = 0
    topoffset[itemtype][frameoffset] = topoffset[itemtype][frameoffset] + 1
    ftemp = frameoffset % 32
    fmult = int(frameoffset/32)
    if not topref.get(ftemp):
        topref[ftemp] = {}
    if not topref[ftemp].get(itemtype):
        topref[ftemp][itemtype] = {}
    if not topref[ftemp][itemtype].get(fmult):
        topref[ftemp][itemtype][fmult] = 0
    topref[ftemp][itemtype][fmult] = topref[ftemp][itemtype][fmult] + 1
    toplist['%4d_%4d_%5d' % (coordx, coordy, frameoffset)] = [ coordx, coordy, bitoff - frameoffset]
lastx = 0
outstring = ''
starty = -1
lasty = -1
lastval = -1
for key, value in sorted(toplist.items()):
    if value[0] != lastx:
        printval(starty, lasty, lastval)
        lastx = value[0]
        print(outstring)
        outstring = '%3d:' % value[0]
        starty = -1
        lasty = -1
        lastval = -1
    if lastval != value[2]:
        printval(starty, lasty, lastval)
        starty = value[1]
    lasty = value[1]
    lastval = value[2]
printval(starty, lasty, lastval)
print(outstring)
#for key, value in sorted(topoffset.items()):
#    outstring = key + ': '
#    for vkey, vvalue in sorted(value.items()):
#        if vvalue != 1:
#            outstring = outstring + ' ' + str(vkey) + '/' + str(vvalue)
#    print(outstring)
print('ref')
for key, value in sorted(topref.items()):
    #print(key, value)
    for vkey, vvalue in sorted(value.items()):
        outstringhead = str(key) + '=' + vkey[6:].strip() + ':'
        outstring = outstringhead
        prevrkey = -1
        for rkey, rvalue in sorted(vvalue.items()):
            if prevrkey != -1 and rkey != prevrkey + 2:
                print(outstring)
                outstring = '    ' + outstringhead
                prevrkey = -1
            outstring = outstring + ' ' + str(rkey)
            if rvalue != 1:
                outstring = outstring + '/' + str(rvalue)
            prevrkey = rkey
    print(outstring)
