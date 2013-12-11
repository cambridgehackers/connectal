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
import optparse, os, sys, re, shutil

masterlist = []
parammap = {}
paramnames = []

def parse_verilog(filename):
    global masterlist
    indata = open(filename).read().expandtabs().split('\n')
    for line in indata:
        ind = line.find('//')
        if ind >= 0:
            line = line[:ind]
        line = line.strip().strip(',').strip()
        ind = line.find('[')
        if ind >= 0:
            f = line[ind+1:].split(']')
            f.insert(0, line[:ind])
            f[1] = f[1].translate(None,' ').lower()
            if f[1][-2:] == ':0':
                f[1] = f[1][:-2]
            if f[1].find('(') >= 0 and f[1][-1] == ')':
                f[1] = f[1][1:-1]
            if f[1][-2:] == '-1':
                f[1] = f[1][:-2]
            else:
                f[1] = str(int(f[1]) + 1)
            if f[1].find('(') >= 0 and f[1][-1] == ')':
                f[1] = f[1][1:-1]
            ind = f[1].find('/')
            if ind > 0:
                item = f[1][:ind]
                newitem = parammap.get(item)
                if newitem:
                    item = newitem
                f[1] = 'TDiv#('+item+','+f[1][ind+1:]+')'
            else:
                newitem = parammap.get(f[1])
                if newitem:
                    f[1] = newitem
            line = f
        else:
            line = line.split()
        f = []
        for ind in range(len(line)):
            item = line[ind].strip()
            if item[-3:] == 'reg':
               item = item[:-3].strip()
            if item != '' and item != 'integer' and item != '=':
                f.append(item)
        if len(f) > 0:
            if f[0][-1] == ';':
                break
            masterlist.append(f)
    masterlist = sorted(masterlist, key=lambda item: item[1] if item[0] == 'parameter' else item[-1])

def translate_verilog(ifname):
    global paramnames
    modulename = ''
    for item in masterlist:
        #print('KK', item)
        if item[0] == 'module':
            modulename = item[1]
        if len(item) > 2 and item[0] != 'parameter':
            item = item[1].strip('0123456789/')
            if len(item) > 0 and item not in paramnames and item[:4] != 'TDiv':
                print('Missing parameter declaration', item, file=sys.stderr)
                paramnames.append(item)
    paramnames.sort()
    paramlist = ''
    for item in paramnames:
        paramlist = paramlist + ', numeric type ' + item
    if paramlist != '':
        paramlist = '#(' + paramlist[2:] + ')'
    print('')
    for item in ['Clocks', 'DefaultValue', 'XilinxCells', 'GetPut']:
        print('import ' + item + '::*;')
    print('')
    #print('(* always_ready, always_enabled *)')
    print('interface ' + ifname + paramlist + ';')
    for item in masterlist:
        itemlen = '1'
        if len(item) > 2:
            itemlen = item[1]
        if item[0] == 'input':
            print('    method Bit#('+itemlen+')     '+item[-1].lower()+'();')
        elif item[0] == 'output':
            print('    method Action      '+item[-1].lower()+'(Bit#('+itemlen+') v);')
        elif item[0] == 'inout':
            print('    interface Inout#(Bit#('+itemlen+'))     '+item[-1].lower()+';')
    print('endinterface')
    print('import "BVI" '+modulename + ' =')
    print('module mk'+ifname+paramlist.replace('numeric type', 'int')+'('+ifname+paramlist.replace('numeric type ', '')+');')
    for item in masterlist:
        if item[0] == 'parameter':
            print('    parameter ' + item[1] + ' = ' + item[2] + ';')
    enindex = 100
    methodlist = ''
    for item in masterlist:
        itemlen = '1'
        if len(item) > 2:
            itemlen = item[1]
        if item[0] == 'input':
            print('    method '+item[-1] + ' ' + item[-1].lower()+'();')
            methodlist = methodlist + ', ' + item[-1].lower()
        elif item[0] == 'output':
            print('    method '+item[-1].lower()+'('+item[-1]+') enable((*inhigh*) en'+str(enindex)+');')
            enindex = enindex + 1
            methodlist = methodlist + ', ' + item[-1].lower()
        elif item[0] == 'inout':
            print('    ifc_inout '+item[-1].lower()+'('+item[-1]+');')
    if methodlist != '':
        methodlist = '(' + methodlist[2:] + ')'
        print('    schedule '+methodlist + ' CF ' + methodlist + ';')
    print('endmodule')

if __name__=='__main__':
    parser = optparse.OptionParser("usage: %prog [options] arg")
    parser.add_option("-f", "--output", dest="filename", help="write data to FILENAME")
    parser.add_option("-p", "--param", action="append", dest="param")
    (options, args) = parser.parse_args()
    #print('KK', options, args, file=sys.stderr)
    for item in options.param:
        item2 = item.split(':')
        if len(item2) == 1:
            if item2[0] not in paramnames:
                paramnames.append(item2[0])
        else:
            parammap[item2[0]] = item2[1]
            if item2[1] not in paramnames:
                paramnames.append(item2[1])
    if len(args) != 1:
        print("incorrect number of arguments", file=sys.stderr)
    else:
        parse_verilog(args[0])
        translate_verilog('PPS7')
