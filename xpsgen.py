##
## Copyright (c) 2013-2014 Quanta Research Cambridge, Inc.

## Permission is hereby granted, free of charge, to any person
## obtaining a copy of this software and associated documentation
## files (the "Software"), to deal in the Software without
## restriction, including without limitation the rights to use, copy,
## modify, merge, publish, distribute, sublicense, and/or sell copies
## of the Software, and to permit persons to whom the Software is
## furnished to do so, subject to the following conditions:

## The above copyright notice and this permission notice shall be
## included in all copies or substantial portions of the Software.

## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
## EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
## MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
## NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
## BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
## ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
## CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
## SOFTWARE.

import sys
import os
import util
import re
import syntax


edkversion = '14.3'
edkversions = ['14.3', '14.4']
if os.environ.has_key('XILINX_EDK'):
    m = re.match('.*/(\d+.\d+)/ISE_DS/EDK$', os.environ['XILINX_EDK'])
    if m:
        edkversion = m.group(1)

xdc_template = '''
set_property iostandard "%(iostandard)s" [get_ports "%(name)s"]
set_property PACKAGE_PIN "%(pin)s" [get_ports "%(name)s"]
set_property slew "SLOW" [get_ports "%(name)s"]
set_property PIO_DIRECTION "%(direction)s" [get_ports "%(name)s"]
'''
xdc_diff_term_template = '''
set_property DIFF_TERM "TRUE" [get_ports "%(name)s"]
'''

impactCmdTemplate = '''
setMode -bscan
setCable -p auto
addDevice -p 1 -file ./%(base)s.runs/impl_1/%(Base)s.bit
program -p 1
quit
'''

programTclTemplate = '''
connect_hw_server
open_hw_target 
set fpga [lindex [get_hw_devices] 0]
set file ./hw/%(Base)s.bit
set_property PROGRAM.FILE $file $fpga
puts "fpga is $fpga, bit file size is [exec ls -sh $file]"
program_hw_devices $fpga
'''

def writeImpactCmd(base, impactcmdname):
        f = util.createDirAndOpen(impactcmdname, 'w')
        f.write(impactCmdTemplate % { 'base': base.lower(), 'Base': base })
        f.close()

def writeProgramTcl(base, programtclname):
        f = util.createDirAndOpen(programtclname, 'w')
        f.write(programTclTemplate % { 'base': base.lower(), 'Base': base })
        f.close()
