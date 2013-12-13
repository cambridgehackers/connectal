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
import io, json, optparse, os, sys, re, tokenize

masterlist = []
parammap = {}
paramnames = []
commoninterfaces = {}
enindex = 0
tokgenerator = 0
toknum = 0
tokval = 0

def parsenext():
    global toknum, tokval
    while True:
        toknum, tokval, _, _, _ = tokgenerator.next()
        if toknum != tokenize.NL and toknum != tokenize.NEWLINE:
            break
    #print('Token:', toknum, tokval)
    if toknum == tokenize.ENDMARKER:
        print('Token: endoffile')
        sys.exit(1)
    return toknum, tokval

def validate_token(testval):
    global toknum, tokval
    if not testval:
        print('Error:Got:', toknum, tokval)
        sys.exit(1)
    parsenext()

def parse_item():
    global toknum, tokval
    #print('ITEMSTART', toknum, tokval)
    tname = tokval
    validate_token(tokval == '(')
    while tokval != ')':
        parsenext()
    validate_token(tokval == ')')
    validate_token(tokval == '{')
    while tokval != '}':
        paramname = tokval
        validate_token(toknum == tokenize.NAME)
        if paramname == 'default_intrinsic_fall' or paramname == 'default_intrinsic_rise':
            validate_token(tokval == ':')
            validate_token(toknum == tokenize.NUMBER)
            continue
        if paramname == 'bus_type':
            validate_token(tokval == ':')
            validate_token(toknum == tokenize.NAME)
            continue
        if tokval == '(':
            while True:
                if paramname not in ['pin', 'timing', 'fpga_condition', 'fpga_condition_value', 'bus']:
                    print('PARSENAME', paramname)
                parse_item()
                paramname = tokval
                if toknum != tokenize.NAME:
                    break
                parsenext()
                if tokval != '(':
                    break
        else:
            validate_token(tokval == ':')
            if toknum == tokenize.NUMBER or toknum == tokenize.NAME or toknum == tokenize.STRING:
                parsenext()
            else:
                validate_token(False)
            if tokval != '}':
                validate_token(tokval == ';')
    validate_token(tokval == '}')
    #print('ITEMEND', toknum, tokval, tokenize.ENDMARKER)

def parse_lib(filename):
    global tokgenerator
    tokgenerator = tokenize.generate_tokens(open(filename).readline)
    parsenext()
    print('PARSEFIRST', tokval)
#tokenize.tok_name)
    validate_token(toknum == tokenize.NAME)
    #while True:
        #toknum, tokval, _, _, _ = tokgenerator.next()
    parse_item()

def generate_interface(ifname, paramval, ilist):
    print('interface ' + ifname + ';')
    for item in ilist:
        itemlen = '1'
        if len(item) > 2:
            itemlen = item[1]
        if item[0] == 'input':
            print('    method Action      '+item[-1].lower()+'(Bit#('+itemlen+') v);')
        elif item[0] == 'output':
            print('    method Bit#('+itemlen+')     '+item[-1].lower()+'();')
        elif item[0] == 'inout':
            print('    interface Inout#(Bit#('+itemlen+'))     '+item[-1].lower()+';')
        elif item[0] == 'interface':
            print('    interface '+item[1]+ paramval +'     '+item[2].lower()+';')
    print('endinterface')

def regroup_items(ifname, masterlist):
    global commoninterfaces
    masterlist = sorted(masterlist, key=lambda item: item[1] if item[0] == 'parameter' else item[-1])
    newlist = []
    currentgroup = ''
    prevlist = []
    for item in masterlist:
        if item[0] != 'input' and item[0] != 'output' and item[0] != 'inout':
            newlist.append(item)
        else:
            litem = item[-1]
#.lower()
            m = re.search('(.+?)(\d+)_(.+)', litem)
            if prevlist != [] and not litem.startswith(currentgroup):
                print('UU', currentgroup, litem, prevlist, file=sys.stderr)
            if m:
                indexname = m.group(2)
                fieldname = m.group(3)
                print('OO', item[-1], m.groups(), file=sys.stderr)
            else:
                m = re.search('(.+?)_(.+)', litem)
                if not m:
                    newlist.append(item)
                    continue
                if len(m.group(1)) == 1: # if only 1 character prefix, get more greedy
                    m = re.search('(.+)_(.+)', litem)
                indexname = ''
                fieldname = m.group(2)
            groupname = m.group(1)
            itemname = groupname + indexname
            if itemname.lower() in ['event']:
                itemname = itemname + '_';
            #fieldname = fieldname + '_';
            interfacename = ifname[0].upper() + ifname[1:].lower() + groupname[0].upper() + groupname[1:].lower()
            if not commoninterfaces.get(interfacename):
                commoninterfaces[interfacename] = {}
            if not commoninterfaces[interfacename].get(indexname):
                commoninterfaces[interfacename][indexname] = []
                newlist.append(['interface', interfacename, itemname, groupname+indexname+'_'])
            foo = item[:-1]
            foo.append(fieldname)
            commoninterfaces[interfacename][indexname].append(foo)
    return newlist

def generate_inter_declarations(paramlist, paramval):
    global commoninterfaces
    for k, v in sorted(commoninterfaces.items()):
        print('interface', k, file=sys.stderr)
        for kuse, vuse in sorted(v.items()):
            if kuse == '' or kuse == '0':
                generate_interface(k+paramlist, paramval, vuse);
            else:
                print('     ', kuse, json.dumps(vuse), file=sys.stderr)

def generate_instance(item, indent, prefix):
    global enindex
    itemlen = '1'
    methodlist = ''
    if len(item) > 2:
        itemlen = item[1]
    if item[0] == 'input':
        print(indent + 'method '+item[-1].lower()+'('+ prefix + item[-1]+') enable((*inhigh*) en'+str(enindex)+');')
        enindex = enindex + 1
        methodlist = methodlist + ', ' + item[-1].lower()
    elif item[0] == 'output':
        print(indent + 'method '+ prefix + item[-1] + ' ' + item[-1].lower()+'();')
        methodlist = methodlist + ', ' + item[-1].lower()
    elif item[0] == 'inout':
        print(indent + 'ifc_inout '+item[-1].lower()+'('+ prefix + item[-1]+');')
    elif item[0] == 'interface':
        print(indent + 'interface '+item[1]+'     '+item[2].lower()+';')
        temp = commoninterfaces[item[1]].get('0')
        if not temp:
            temp = commoninterfaces[item[1]]['']
        for titem in temp:
             generate_instance(titem, '        ', item[3])
        print('    endinterface')
    return methodlist

def translate_verilog(ifname):
    global paramnames, enindex
    modulename = ''
    # check for parameterized declarations
    for item in masterlist:
        #print('KK', item)
        if item[0] == 'module':
            modulename = item[1]
        if item[0] == 'input' or item[0] == 'output' or item[0] == 'inout':
            item = item[1].strip('0123456789/')
            if len(item) > 0 and item not in paramnames and item[:4] != 'TDiv':
                print('Missing parameter declaration', item, file=sys.stderr)
                paramnames.append(item)
    paramnames.sort()
    # generate output file
    print('')
    for item in ['Clocks', 'DefaultValue', 'XilinxCells', 'GetPut']:
        print('import ' + item + '::*;')
    print('')
    #print('(* always_ready, always_enabled *)')
    paramlist = ''
    for item in paramnames:
        paramlist = paramlist + ', numeric type ' + item
    if paramlist != '':
        paramlist = '#(' + paramlist[2:] + ')'
    paramval = paramlist.replace('numeric type ', '')
    generate_inter_declarations(paramlist, paramval)
    generate_interface(ifname + paramlist, paramval, masterlist)
    print('import "BVI" '+modulename + ' =')
    print('module mk'+ifname+paramlist.replace('numeric type', 'int')+'('+ifname+ paramval +');')
    for item in masterlist:
        if item[0] == 'parameter':
            print('    parameter ' + item[1] + ' = ' + item[2] + ';')
    enindex = 100
    methodlist = ''
    for item in masterlist:
        methodlist = methodlist + generate_instance(item, '    ', '')
    if methodlist != '':
        methodlist = '(' + methodlist[2:] + ')'
        print('    schedule '+methodlist + ' CF ' + methodlist + ';')
    print('endmodule')

if __name__=='__main__':
    parser = optparse.OptionParser("usage: %prog [options] arg")
    parser.add_option("-f", "--output", dest="filename", help="write data to FILENAME")
    (options, args) = parser.parse_args()
    ifname = 'PPS7'
    #print('KK', options, args, file=sys.stderr)
    if len(args) != 1:
        print("incorrect number of arguments", file=sys.stderr)
    else:
        parse_lib(args[0])
        #masterlist = regroup_items(ifname, masterlist)
        #translate_verilog(ifname)
