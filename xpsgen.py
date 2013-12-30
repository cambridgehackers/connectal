
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
use_acp = 0


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
