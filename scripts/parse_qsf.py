#!/usr/bin/env python3

from __future__ import print_function
import sys
import json
import re
import argparse

argparser = argparse.ArgumentParser("Parse QSF to Json")
argparser.add_argument('-q', '--qsf', help='Input QSF File')
argparser.add_argument('-g', '--group', default=[], help='Signal Group', action='append')
argparser.add_argument('-o', '--output', default=None, help='Write output to file')

options = argparser.parse_args()
qsffile = options.qsf

groups = {}
for group in options.group:
    split = group.split(':')
    groups[split[0]] = split[1]

qsflines = open(qsffile).readlines()

out = sys.stdout
if options.output:
    out = open(options.output, 'w')

group=''
pins={}
for line in qsflines:
    # Skip comments
    m = re.search("#*=", line)
    if m:
        continue

    # Find group name
    m = re.search('#', line)
    if m:
        group = line.replace('#','').strip()
        groups.update({group:{}})

    # Find pin name
    m = re.search('set_instance_assignment', line)
    if m:
        n = re.search('-to', line)
        if n:
            r = line.split('-to')[0].strip()
            name = line.split('-to')[1].strip()

            io = re.search('IO_STANDARD', r)
            if io:
                standard = r.split('IO_STANDARD')[1].strip().replace("\"", '')
                if name in pins:
                    pins[name].update({'IO_STANDARD': standard})
                    pins[name].update({'GROUP': group})
                else:
                    pins.update({name: {'IO_STANDARD': standard}})
                    pins[name].update({'GROUP': group})

    # Find pin location
    m = re.search('set_location_assignment', line)
    if m:
        n = re.search('-to', line)
        if n:
            r = line.split('-to')[0].strip()
            name = line.split('-to')[1].strip()

            loc = re.search('PIN_[A-Z]+[0-9]+', r)
            if loc:
                location = loc.group(0)
                if name in pins:
                    pins[name].update({'LOC': location})
                else:
                    pins.update({name:{'LOC': location}})

for n in pins:
    groups[pins[n]['GROUP']].update({n: {'IOSTANDARD': pins[n]['IO_STANDARD'], 'LOC': pins[n]['LOC']}})

print(json.dumps(groups, indent=4, sort_keys=True), file=out)
