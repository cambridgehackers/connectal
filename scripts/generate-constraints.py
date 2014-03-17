#!/usr/bin/python

import sys
import json

boardfile = sys.argv[1]
pinoutfile = sys.argv[2]

pinstr = open(pinoutfile).read()
pinout = json.loads(pinstr)

boardInfo = json.loads(open(boardfile).read())

template='''\
set_property LOC "%(LOC)s" [get_ports "%(name)s"]
set_property IOSTANDARD "%(IOSTANDARD)s" [get_ports "%(name)s"]
set_property PIO_DIRECTION "%(PIO_DIRECTION)s" [get_ports "%(name)s"]
'''
for pin in pinout:
    pinInfo = pinout[pin]
    loc = 'TBD'
    iostandard = 'TBD'
    if pinInfo.has_key('fmc'):
        fmcPin = pinInfo['fmc']
        if boardInfo.has_key(fmcPin):
            loc = boardInfo[fmcPin]['LOC']
            iostandard = boardInfo[fmcPin]['IOSTANDARD']
        else:
            loc = 'fmc.%s' % (fmcPin)
    print template % {
        'name': pin,
        'LOC': loc,
        'IOSTANDARD': iostandard,
        'PIO_DIRECTION': pinInfo['PIO_DIRECTION']
        }

