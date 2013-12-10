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
import os, sys, re, shutil

masterlist = []

def parse_verilog(filename):
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
            f[1] = f[1].translate(None,' ')
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
                return
            masterlist.append(f)

def translate_verilog():
    modulename = ''
    params = []
    for item in masterlist:
        #print('KK', item)
        if item[0] == 'module':
            modulename = item[1]
        if len(item) > 2 and item[0] != 'parameter':
            item = item[1].strip('0123456789/')
            if len(item) > 0 and item not in params:
                params.append(item)
    params.sort()
    paramlist = ''
    for item in params:
        paramlist = paramlist + ', numeric type ' + item
    if paramlist != '':
        paramlist = '#(' + paramlist[2:] + ')'
    print('interface ' + modulename + paramlist + ';')
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
    ifname = 'PS7'
    print('import "BVI" '+modulename + ' =')
    print('module mk'+ifname+paramlist+'('+ifname+paramlist+');')
    for item in masterlist:
        if item[0] == 'parameter':
            print('    parameter ' + item[1] + ' = ' + item[2] + ';')
    enindex = 100
    for item in masterlist:
        itemlen = '1'
        if len(item) > 2:
            itemlen = item[1]
        if item[0] == 'input':
            print('    method '+item[-1] + ' ' + item[-1].lower()+'();')
        elif item[0] == 'output':
            print('    method '+item[-1].lower()+'('+item[-1]+') enable((*inhigh*) en'+str(enindex)+');')
            enindex = enindex + 1
        elif item[0] == 'inout':
            print('    ifc_inout '+item[-1].lower()+'('+item[-1]+');')
    print('endmodule')

if __name__=='__main__':
    parse_verilog(sys.argv[1])
    translate_verilog()
