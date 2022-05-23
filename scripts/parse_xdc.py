#!/usr/bin/env python3

# parse xdc pin assignment to json

from __future__ import print_function
import sys
import json
import re
import argparse

argparser = argparse.ArgumentParser("Parse XDC to Json")
argparser.add_argument('-x', '--xdc', help='Input XDC File')
argparser.add_argument('-g', '--group', default=[], help='Signal Group', action='append')
argparser.add_argument('-o', '--output', default=None, help='Write output to file')

options = argparser.parse_args()
xdcfile = options.xdc

groups = {}
for group in options.group:
    split = group.split(':')
    groups[split[0]] = split[1]

xdclines = open(xdcfile).readlines()

out = sys.stdout
if options.output:
    out = open(options.output, 'w')

group=''
pins={}
for line in xdclines:
    # Find group name
    m = re.search('^#', line)
    if m:
        group = line.replace('#','').strip()
        groups.update({group:{}})

    # Find pin name and location
    m = re.search('^set_property', line)
    if m:
        n = re.search('-dict', line)
        if n:
            r = line.split('-dict')[0].strip()
            line = line.split('-dict')[1].strip()
            name = line.split('get_ports')[1].split('{')[1].split('}')[0].strip()

            loc = re.search('PACKAGE_PIN', line)
            if loc:
                pin = line.split('PACKAGE_PIN')[1].split()[0].strip().replace("\"", '')
                if name in pins:
                    pins[name].update({'LOC': pin})
                    pins[name].update({'GROUP': group})
                else:
                    pins.update({name:{'LOC': pin}})
                    pins[name].update({'GROUP': group})

            io = re.search('IOSTANDARD', line)
            if io:
                standard = line.split('IOSTANDARD')[1].split()[0].strip().replace("\"", '')
                if standard in pins:
                    pins[name].update({'IOSTANDARD': standard})
                else:
                    pins[name].update({'IOSTANDARD': standard})

for n in pins:
    groups[pins[n]['GROUP']].update({n: {'IOSTANDARD': pins[n]['IOSTANDARD'], 'LOC': pins[n]['LOC']}})

print(json.dumps(groups, indent=4, sort_keys=True), file=out)
