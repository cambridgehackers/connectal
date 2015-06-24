#!/usr/bin/python

import sys, re

failed = 0
for timingreport in sys.argv[1:]:
    for line in open(timingreport):
        re_no_clock = re.compile('\s*There are (\d+) register/latch pins with no clock(.*)')
        re_constant_clock = re.compile('\s*There are (\d+) .*constant_clock(.*)')
        re_violated = re.compile('.*VIOLATED.*-([.0-9]+)')

        m = re_no_clock.match(line)
        if m and int(m.group(1)):
            print '*** no clock pins ***'
            print line
            failed = 1
        m = re_constant_clock.match(line)
        if m and int(m.group(1)):
            print '*** constant clock pins ***'
            print line
            failed = 1
        m = re_violated.match(line)
        if m and float(m.group(1)) >= 0.1:
            print '*** timing violation ***'
            print line
            failed = 1
if failed:
    sys.exit(-11)


