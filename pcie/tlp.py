#!/usr/bin/env python3

from __future__ import print_function

import os
import re
import sys
import subprocess
from gmpy import mpz

# 64-bit BAR
tlpdatalog = [
    '000000011184ffff4a000001020000040018001068470000',
    '000000020984fff0000000010018000fdf508000e775b7be',
    '000000031184ffff4a0000010200000400180000bad0dada',
    '000000040984fff0000000010018000fdf5040002c7bdba8',
    '000000051184ffff4a0000010200000400180000005a05a0',
    '000000060984fff0000000010018000fdf5000001ce1d27f',
    '000000071184ffff4a0000010200000400180000005b05b0',
    '000000080984fff0000000010018000fdf5040009c773d52',
    '000000091184ffff4a0000010200000400180000005a05a0',
    '0000000a0984fff0000000010018000fdf50c0107d93c3c9',
    '0000000b1184ffff4a000001020000040018001068470000',
    '0000000c0984fff0000000010018000fdf50800099159bf9',
    '0000000d1184ffff4a0000010200000400180000bad0dada',
    '0000000e0984fff0000000010018000fdf5040008fc4124f',
    '0000000f1184ffff4a0000010200000400180000005a05a0',
    '000000100984fff0000000010018000fdf5000000f52fd62',
]

TlpPacketType = [
    'MEMORY_READ_WRITE',
    'MEMORY_READ_LOCKED',
    'IO_REQUEST',
    'UNKNOWN_TYPE_3',
    'CONFIG_0_READ_WRITE',
    'CONFIG_1_READ_WRITE',
    'UNKNOWN_TYPE_6',
    'UNKNOWN_TYPE_7',
    'UNKNOWN_TYPE_8',
    'UNKNOWN_TYPE_9',
    'COMPLETION',
    'COMPLETION_LOCKED',
    'UNKNOWN_TYPE_12',
    'UNKNOWN_TYPE_13',
    'UNKNOWN_TYPE_14',
    'UNKNOWN_TYPE_15',
    'MSG_ROUTED_TO_ROOT',
    'MSG_ROUTED_BY_ADDR',
    'MSG_ROUTED_BY_ID',
    'MSG_ROOT_BROADCAST',
    'MSG_LOCAL',
    'MSG_GATHER',
    'UNKNOWN_TYPE_22',
    'UNKNOWN_TYPE_23',
    'UNKNOWN_TYPE_24',
    'UNKNOWN_TYPE_25',
    'UNKNOWN_TYPE_26',
    'UNKNOWN_TYPE_27',
    'UNKNOWN_TYPE_28',
    'UNKNOWN_TYPE_29',
    'UNKNOWN_TYPE_30',
    'UNKNOWN_TYPE_31'
]

TlpPacketFormat = [
    'MEM_READ_3DW_NO_DATA',
    'MEM_READ_4DW_NO_DATA',
    'MEM_WRITE_3DW_DATA',
    'MEM_WRITE_4DW_DATA'
]

first_vcd_timestamp = mpz(0)
last_vcd_timestamp = mpz(0)
last_vcd_pktclass_code = None

pktclassCodes = {
    'Slave Request': 'S',
    'Slave Write Request': 'T',
    'Slave Response': 's',
    'slave continuation': 'c',
    'Master Write Request': 'W',
    'Master Request': 'M',
    'Master Response': 'm',
    'master continuation': 'C',
    'trace': 't',
}

vcd_header_template='''
$version
   tlp.py
$end
$comment
$end
$timescale 8ns $end
$scope module logic $end
%(vars)s
$upscope $end
$enddefinitions $end
'''

unused='''
$dumpvars
%(dumpvars)s
$end
'''

def emit_vcd_header(f):
    f.write(vcd_header_template
            % { 'vars': '\n'.join(['$var wire 1 %s %s $end' % (pktclassCodes[k], k.lower().replace(' ', '_')) for k in pktclassCodes]),
                'dumpvars': '\n'.join(['0%s' % pktclassCodes[k] for k in pktclassCodes])
            })

def emit_vcd_entry(f, timestamp, pktclass):
    global first_vcd_timestamp, last_vcd_timestamp, last_vcd_pktclass_code
    if not timestamp:
        return
    if not first_vcd_timestamp:
        first_vcd_timestamp = timestamp
    print(last_vcd_timestamp, timestamp, (timestamp < last_vcd_timestamp))
    if last_vcd_timestamp and (timestamp < last_vcd_timestamp):
        f.write('$comment %s %s %s $end\n' % (hex(last_vcd_timestamp), hex(timestamp), hex(timestamp + mpz('100000000', 16))))
        timestamp = timestamp + mpz('100000000', 16)
        f.write('$comment %s %s $end\n' % (hex(timestamp), hex(timestamp - first_vcd_timestamp)))

    #timestamp = timestamp - first_vcd_timestamp

    if last_vcd_timestamp and timestamp > (last_vcd_timestamp+1):
        f.write('#%s\n0%s\n' % ((last_vcd_timestamp+mpz(1)), last_vcd_pktclass_code))
    if pktclass in pktclassCodes:
        pktclass_code = pktclassCodes[pktclass]
        f.write('#%s\n' % timestamp)
        f.write('1%s\n' % pktclass_code)
        if last_vcd_pktclass_code and last_vcd_pktclass_code != pktclass_code:
            f.write('0%s\n' % last_vcd_pktclass_code)
        last_vcd_pktclass_code = pktclass_code
        last_vcd_timestamp = timestamp
    else:
        f.write('$comment %s $end\n' % pktclass)

def pktClassification(tlpsof, tlpeof, tlpbe, pktformat, pkttype, portnum):
    if tlpbe == '0000':
        return 'trace'
    if tlpsof == 0:
        if portnum == 4:
            return 'master continuation'
        else:
            return 'slave continuation'
    if portnum == 4:
        if pkttype == 10: # COMPLETION
            return 'Master Response'
        else:
            if pktformat == 2 or pktformat == 3:
                return 'Slave Write Request'
            else:
                return 'Slave Request'
    elif portnum == 8:
        if pkttype == 10: # COMPLETION
            return 'Slave Response'
        else:
            if pktformat == 2 or pktformat == 3:
                return 'Master Write Request'
            else:
                return 'Master Request'
    else:
        return 'Misc'

classCounts = {}
last_seqno = mpz(-1)

def print_tlp(tlpdata, f=None):
    global last_seqno
    def segment(i):
        return tlpdata[i*8:i*8+8]
    def byteswap(w):
        def byte(i):
            return w[i*2:i*2+2]
        return ''.join(map(byte, [3,2,1,0]))

    words = map(segment, [0,1,2,3,4,5])

    seqno = mpz(tlpdata[-48:-40],16)
    if last_seqno >= 0:
        delta = seqno - last_seqno
    else:
        delta = 0
    tlpsof = int(tlpdata[-39:-38],16) & 1
    tlpeof = int(tlpdata[-38:-36],16) >> 7
    tlpbe  = tlpdata[-36:-32]
    tlphit = int(tlpdata[-38:-36],16) & 0x7f
    pktformat = (int(tlpdata[-32:-31],16) >> 1) & 3
    pkttype = (int(tlpdata[-32:-30],16) & 0x1f)

    portnum = int(tlpdata[-40:-38],16) >> 1
    pktclass = pktClassification(tlpsof, tlpeof, tlpbe, pktformat, pkttype, portnum)
    if pktclass in classCounts:
       classCounts[pktclass] += 1
    else:
       classCounts[pktclass] = 1

    if f:
        emit_vcd_entry(f, seqno, pktclass)

    print(tlpdata)
    print('timestamp:', seqno)
    print('    delta:', delta)
    last_seqno = seqno
    print('   ', pktclass)
    print('    foo:', tlpdata[-40:-38], hex(int(tlpdata[-40:-38],16) >> 1))
    print('    tlpbe:', tlpbe)
    print('    tlphit:', tlphit)
    print('    tlpeof:', tlpeof)
    print('    tlpsof:', tlpsof)
    if tlpsof:
        print('    format:', tlpdata[-32:-31], pktformat, TlpPacketFormat[pktformat])
        print('   pkttype:', tlpdata[-32:-30], pkttype, TlpPacketType[pkttype])

    if tlpsof == 0:
        print('     data:', tlpdata[-32:])
    elif TlpPacketFormat[pktformat] == 'MEM_WRITE_3DW_DATA' and TlpPacketType[pkttype] == 'COMPLETION':
        print('      tag:', tlpdata[-12:-10])
        print('    reqid:', tlpdata[-16:-12])
        print('   cmplid:', tlpdata[-24:-20])
        print('   status:', tlpdata[-20:-19])
        print('  nosnoop:', tlpdata[-28:-27], int(tlpdata[-28:-27],16) >> 3)
        print('bytecount:', tlpdata[-19:-16])
        print('loweraddr:', tlpdata[-10:-8])
        print('  length:', int(tlpdata[-27:-24],16) & 0x3ff)
        print('    data:', tlpdata[-8:])
    elif TlpPacketFormat[pktformat] == 'MEM_READ_3DW_NO_DATA' or TlpPacketFormat[pktformat] == 'MEM_WRITE_3DW_DATA':
        print(' address:', tlpdata[-16:-8], (int(tlpdata[-16:-8],16) >> 2) % 8192)
        print('  1st be:', tlpdata[-17:-16])
        print(' last be:', tlpdata[-18:-17])
        print('     tag:', tlpdata[-20:-18])
        print('   reqid:', tlpdata[-24:-20])
        print('  length:', int(tlpdata[-27:-24],16) & 0x3ff)
        if TlpPacketFormat[pktformat] == 'MEM_WRITE_3DW_DATA':
            print('    data:', tlpdata[-8:])
    elif TlpPacketFormat[pktformat] == 'MEM_READ_4DW_NO_DATA' or TlpPacketFormat[pktformat] == 'MEM_WRITE_4DW_DATA':
        print(' address:', tlpdata[-16:])
        print('  1st be:', tlpdata[-17:-16])
        print(' last be:', tlpdata[-18:-17])
        print('     tag:', tlpdata[-20:-18])
        print('   reqid:', tlpdata[-24:-20])
        print('  length:', int(tlpdata[-27:-24],16) & 0x3ff)
    else:
        print('  tlp data:', tlpdata[-8:])
        print('lower addr:', tlpdata[-10:-8])
        print('       tag:', tlpdata[-12:-10])
        print('     reqid:', tlpdata[-14:-12])
        print(' bytecount:', '0x' + tlpdata[-15:-14])
        print('       bcm:', int(tlpdata[-16:-15], 16) & 1)
        print('   cstatus:', (int(tlpdata[-16:-15], 16) >> 1) & 7)
        print('    cmplid:', tlpdata[-18:-16])
        print('    cmplen:', tlpdata[-21:-18])
        print('   nosnoop:', int(tlpdata[-22:-21],16) & 1)
        print('   relaxed:', int(tlpdata[-22:-21],16) & 2)
        print('   poison:', int(tlpdata[-22:-21],16) & 4)
        print('   digest:', int(tlpdata[-22:-21],16) & 8)
        print('     zero:', tlpdata[-23:-22])
        print('   tclass:', tlpdata[-24:-23])
        print('  pkttype:', int(tlpdata[-26:-24],16) & 0x1f, TlpPacketType[int(tlpdata[-26:-24],16) & 0x1f])
        print('  format:', (int(tlpdata[-26:-24],16) >> 1) & 3, TlpPacketFormat[(int(tlpdata[-26:-24],16) >> 1) & 3])
    print()

def print_tlp_log(tlplog, f=None):
    if f:
        emit_vcd_header(f)
    for tlpdata in tlplog:
        if tlpdata == '000000000000000000000000000000000000000000000000':
            continue
        m = re.match('^([0-9A-Fa-f]+)$', tlpdata)
        if m:
            print_tlp(tlpdata, f)

if __name__ == '__main__':
    f = open('tlp.vcd', 'w')
    if len(sys.argv) > 1 and sys.argv[1] == 'openocd':
        os.chdir('/scratch/jamey/connectal/jtag')
        tlplog = subprocess.check_output(['openocd', '-f', 'pcietrace.cfg'], stderr=subprocess.STDOUT).split('\n')
    elif len(sys.argv) > 1:
        tlplog = open(sys.argv[1]).read().split('\n')
    else:
        tlplog = subprocess.check_output(['connectalutil', 'tlp', '/dev/portal0']).split('\n')
    print_tlp_log(tlplog[0:-1], f)
    print(classCounts)
    print(sum([ classCounts[k] for k in classCounts]))
