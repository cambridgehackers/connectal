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

def getbit(lastx, lasty):
    toff = 36 * int((lastx - 14)/2)
    if lastx >= 54:
        toff = toff + 2 + 4 * 28
    elif lastx >= 50: # column X1
        toff = toff + 2 + 3 * 28
    elif lastx >= 36:
        toff = toff + 2 * 28
    elif lastx >= 32:
        toff = toff + 28
    if lasty <= 49:   # row Y0
        toff = toff + 2 * 2 * 1283
    elif lasty <= 99: # row Y1
        toff = toff + 2 * 1283
    return toff

def printval(starty, lastx, lasty, lastval):
    if starty == -1:
        return ''
    return ' %3d-%3d/%d' % (starty, lasty, lastval - getbit(lastx, lasty))

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
    toplist['%4d_%4d_%5d' % (coordx, coordy, frameoffset)] = [ coordx, coordy, (bitoff - frameoffset)/ 3232.0 - 467]
lastx = 0
outstring = ''
starty = -1
lasty = -1
lastval = -1
for key, value in sorted(toplist.items()):
    if value[0] != lastx:
        outstring = outstring + printval(starty, lastx, lasty, lastval)
        lastx = value[0]
        print(outstring)
        outstring = '%3d:' % value[0]
        starty = -1
    if lastval != value[2]:
        outstring = outstring + printval(starty, lastx, lasty, lastval)
        starty = value[1]
    lasty = value[1]
    lastval = value[2]
outstring = outstring + printval(starty, lastx, lasty, lastval)
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
