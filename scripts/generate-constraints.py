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
import json
import argparse

argparser = argparse.ArgumentParser("Generate constraints file for board.")
argparser.add_argument('boardfile', help='Board description file (json)')
argparser.add_argument('pinoutfile', help='Project description file (json)')
argparser.add_argument('-b', '--bind', default=[], help='Bind signal group to pin group', action='append')
argparser.add_argument('-o', '--output', default=None, help='Write output to file')
argparser.add_argument('-f', '--fpga', default="xilinx", help='Target FPGA Vendor')

options = argparser.parse_args()
boardfile = options.boardfile
pinoutfile = options.pinoutfile
errorDetected = False

bindings = {
    'pins': 'pins',
    'pin_name': 'pins' # legacy
    }
for binding in options.bind:
    split = binding.split(':')
    bindings[split[0]] = split[1]


pinstr = open(pinoutfile).read()
pinout = json.loads(pinstr)

boardInfo = json.loads(open(boardfile).read())

if options.fpga == "xilinx":
    template='''\
set_property LOC "%(LOC)s" [get_ports "%(name)s"]
set_property IOSTANDARD "%(IOSTANDARD)s" [get_ports "%(name)s"]
set_property PIO_DIRECTION "%(PIO_DIRECTION)s" [get_ports "%(name)s"]
    '''
    setPropertyTemplate='''\
    set_property %(prop)s "%(val)s" [get_ports "%(name)s"]
    '''
elif options.fpga == "altera":
    template='''\
set_instance_assignment -name IO_STANDARD "%(IOSTANDARD)s" -to "%(name)s"
set_location_assignment "%(LOC)s" -to "%(name)s"
'''
    setPropertyTemplate=""

out = sys.stdout
if options.output:
    out = open(options.output, 'w')

for pin in pinout:
    pinInfo = pinout[pin]
    loc = 'TBD'
    iostandard = 'TBD'
    iodir = 'TBD'
    used = []
    boardGroupInfo = {}
    pinName = ''
    #print('PPP', pinInfo)
    for key in bindings:
        if pinInfo.has_key(key):
            used.append(key)
            pinName = pinInfo[key]
            #print('LLL', key, pinName, bindings[key])
            boardGroupInfo = boardInfo[bindings[key]]
            break
    if pinName == '':
        for key in pinInfo:
            #print('JJJJ', key)
            if boardInfo.get(key):
                pinName = pinInfo[key]
                boardGroupInfo = boardInfo[key]
                #print('FFF', key, pinName, boardGroupInfo, boardGroupInfo.has_key(pinName), boardGroupInfo.get(pinName))
                break
    if boardGroupInfo == {}:
        print('Missing group description for', pinName, pinInfo, file=sys.stderr)
        errorDetected = True
    if boardGroupInfo.has_key(pinName):
        if boardGroupInfo[pinName].has_key('LOC'):
            loc = boardGroupInfo[pinName]['LOC']
        else:
            loc = boardGroupInfo[pinName]['PACKAGE_PIN']
        iostandard = boardGroupInfo[pinName]['IOSTANDARD']
        if boardGroupInfo[pinName].has_key('PIO_DIRECTION'):
            iodir = boardGroupInfo[pinName]['PIO_DIRECTION']
    else:
        print('Missing pin description for', pinName, pinInfo, file=sys.stderr)
        loc = 'fmc.%s' % (pinName)
        errorDetected = True
    if pinInfo.has_key('IOSTANDARD'):
        iostandard = pinInfo['IOSTANDARD']
    if pinInfo.has_key('PIO_DIRECTION'):
        iodir = pinInfo['PIO_DIRECTION']
    out.write(template % {
            'name': pin,
            'LOC': loc,
            'IOSTANDARD': iostandard,
            'PIO_DIRECTION': iodir
            })
    for k in pinInfo:
        if k in used+['IOSTANDARD', 'PIO_DIRECTION']: continue
        out.write(setPropertyTemplate % {
                'name': pin,
                'prop': k,
                'val': pinInfo[k],
                })
if errorDetected:
    sys.exit(-1);
