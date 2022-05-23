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
import argparse, json, sys
from collections import OrderedDict
import copy

bindings = {
    #'pins': 'pins',
    'pin_name': 'pins' # legacy
    }
errorDetected = False

def newArgparser():
    argparser = argparse.ArgumentParser("Generate constraints file for board.")
    argparser.add_argument('--boardfile', help='Board description file (json)')
    argparser.add_argument('--pinoutfile', default=[], help='Project description file (json)', action='append')
    argparser.add_argument('-b', '--bind', default=[], help='Bind signal group to pin group', action='append')
    argparser.add_argument('-o', '--output', default=None, help='Write output to file')
    argparser.add_argument('-f', '--fpga', default="xilinx", help='Target FPGA Vendor')
    return argparser


if __name__=='__main__':
    argparser=newArgparser()
    options = argparser.parse_args()

    for binding in options.bind:
        split = binding.split(':')
        bindings[split[0]] = split[1]

    boardInfo = json.loads(open(options.boardfile).read())
    print(options.fpga)
    if options.fpga == "xilinx":
        template='''\
    set_property PACKAGE_PIN "%(PACKAGE_PIN)s" [get_ports "%(name)s"]
    set_property PIO_DIRECTION "%(PIO_DIRECTION)s" [get_ports "%(name)s"]
        '''
        setPropertyTemplate='''\
        set_property %(prop)s "%(val)s" [get_ports "%(name)s"]
        '''
    elif options.fpga == "altera":
        template='''\
    set_location_assignment "%(LOC)s" -to "%(name)s"
    '''
        setPropertyTemplate='''\
    set_instance_assignment -name %(prop)s "%(val)s" -to "%(name)s"
    '''

    out = sys.stdout
    if options.output:
        out = open(options.output, 'w')

    for filename in options.pinoutfile:
        print('generate-constraints: processing file "' + filename + '"')
        pinstr = open(filename).read()
        pinout = json.loads(pinstr, object_pairs_hook=OrderedDict)
        for pin in pinout:
            projectPinInfo = pinout[pin]
            loc = 'TBD'
            iodir = 'TBD'
            used = []
            boardPinInfo = {}
            pinName = ''
            #print('PPP', projectPinInfo)
            for groupName in bindings:
                if groupName in projectPinInfo:
                    used.append(groupName)
                    pinName = projectPinInfo[groupName]
                    #print('LLL', groupName, pinName, bindings[groupName])
                    boardPinInfo = boardInfo[bindings[groupName]]
                    break
            if pinName == '':
                for prop in projectPinInfo:
                    #print('JJJJ', prop)
                    if boardInfo.get(prop):
                        used.append(prop)
                        pinName = projectPinInfo[prop]
                        boardPinInfo = boardInfo[prop]
                        #print('FFF', prop, pinName, boardPinInfo, pinName in boardPinInfo, boardPinInfo.get(pinName))
                        break
            if boardPinInfo == {}:
                print('Missing group description for', pin, pinName, projectPinInfo, file=sys.stderr)
                errorDetected = True
            pinInfo = {}
            if pinName in boardPinInfo:
                pinInfo = copy.copy(boardPinInfo[pinName])
            else:
                print('Missing pin description for', pin, pinName, projectPinInfo, file=sys.stderr)
                pinInfo['PACKAGE_PIN'] = 'fmc.%s' % (pinName)
                errorDetected = True
            pinInfo[u'name'] = pin
            for prop in projectPinInfo:
                if prop in projectPinInfo:
                    pinInfo[prop] = projectPinInfo[prop]
            try:
                out.write(template % pinInfo)
            except:
                print('missing attributes for pin ', pinName)
                print(template)
                print(pinInfo)
            for k in pinInfo:
                if k in used+['name', 'PACKAGE_PIN', 'PIO_DIRECTION']: continue
                out.write(setPropertyTemplate % {
                        'name': pin,
                        'prop': k,
                        'val': pinInfo[k],
                        })
    if errorDetected:
        sys.exit(-1);
