#!/usr/bin/python

import sys, re

failed = 0
for line in open(sys.argv[1]):
    re_no_clock = re.compile('\s*There are 2996 register/latch pins with no clock driven by root clock pin:(.*)')
    re_constant_clock = re.compile('\s*There are (\d+) register/latch pins with constant_clock.')
    re_violated = re.compile('\s*Slack (VIOLATED) :        -([.\d]+)ns  (required time - arrival time)')

    m = re_no_clock.match(line)
    if m:
        print '*** no clock pins ***'
        print line
        failed = 1
    m = re_constant_clock.match(line)
    if m and int(m.group(1)) > 0:
        print '*** constant clock pins ***'
        print line
        failed = 1
    m = re_violated.match(line)
    if m:
        print '*** timing violation ***'
        print line
        failed = 1
if failed:
    sys.exit(-11)


