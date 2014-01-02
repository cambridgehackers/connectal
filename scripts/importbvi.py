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
import json, optparse, os, sys, re, tokenize
#names of tokens: tokenize.tok_name

masterlist = []
parammap = {}
paramnames = []
remapmap = {}
clocknames = []
commoninterfaces = {}
tokgenerator = 0
clock_params = []
toknum = 0
tokval = 0
modulename = ''

#
# parser for .lib files
#
def parsenext():
    global toknum, tokval
    while True:
        toknum, tokval, _, _, _ = tokgenerator.next()
        if toknum != tokenize.NL and toknum != tokenize.NEWLINE:
            break
    #print('Token:', toknum, tokval)
    if toknum == tokenize.ENDMARKER:
        print('Token: endoffile')
        return None, None
    return toknum, tokval

def validate_token(testval):
    global toknum, tokval
    if not testval:
        print('Error:Got:', toknum, tokval)
        sys.exit(1)
    parsenext()

def parseparam():
    paramstr = ''
    validate_token(tokval == '(')
    while tokval != ')' and toknum != tokenize.ENDMARKER:
        paramstr = paramstr + tokval
        parsenext()
    validate_token(tokval == ')')
    validate_token(tokval == '{')
    return paramstr

def parse_item():
    global masterlist
    paramlist = {}
    while tokval != '}' and toknum != tokenize.ENDMARKER:
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
            paramlist['attr'] = []
            while True:
                paramstr = parseparam()
                plist = parse_item()
                if paramstr != '' and paramname != 'fpga_condition':
                    for mitem in remapmap:
                        if paramstr.startswith(mitem):
                            paramstr = remapmap[mitem] + paramstr[len(mitem):]
                        #print('RRR', mitem, paramstr)
                    if plist == {}:
                        paramlist['attr'].append([paramstr])
                    else:
                        paramlist['attr'].append([paramstr, plist])
                if paramname == 'cell':
                    #print('CC', paramstr)
                    pinlist = {}
                    for item in plist['attr']:
                        tname = item[0]
                        tlist = item[1]
                        tdir = 'unknowndir'
                        if tlist.get('direction'):
                            tdir = tlist['direction']
                            del tlist['direction']
                        tsub = ''
                        ind = tname.find('[')
                        if ind > 0:
                            tsub = tname[ind+1:-1]
                            tname = tname[:ind]
                        titem = [tdir, tsub, tlist]
                        ttemp = pinlist.get(tname)
                        if not ttemp:
                            pinlist[tname] = titem
                        elif ttemp[0] != titem[0] or ttemp[2] != titem[2]: 
                            print('different', tname, ttemp, titem)
                        elif ttemp[1] != titem[1]: 
                            if int(titem[1]) > int(ttemp[1]):
                                ttemp[1] = titem[1]
                            else:
                                print('differentindex', tname, ttemp, titem)
                    for k, v in sorted(pinlist.items()):
                        if v[1] == '':
                            ttemp = [v[0], k]
                        else:
                            ttemp = [v[0], str(int(v[1])+1), k]
                        if v[2] != {}:
                            ttemp.append(v[2])
                        if paramstr == 'PS7':
                            masterlist.append(ttemp)
                paramname = tokval
                if toknum != tokenize.NAME:
                    break
                parsenext()
                if tokval != '(':
                    break
        else:
            validate_token(tokval == ':')
            if paramname not in ['fpga_arc_condition', 'function', 'next_state']:
                paramlist[paramname] = tokval
            if toknum == tokenize.NUMBER or toknum == tokenize.NAME or toknum == tokenize.STRING:
                parsenext()
            else:
                validate_token(False)
            if tokval != '}':
                validate_token(tokval == ';')
    validate_token(tokval == '}')
    if paramlist.get('attr') == []:
        del paramlist['attr']
    return paramlist

def parse_lib(filename):
    global tokgenerator, masterlist
    tokgenerator = tokenize.generate_tokens(open(filename).readline)
    parsenext()
    print('PARSEFIRST', tokval)
    if tokval != 'library':
        sys.exit(1)
    validate_token(toknum == tokenize.NAME)
    parseparam()
    parse_item()
    searchlist = []
    for item in masterlist:
        ind = item[-1].find('1')
        if ind > 0:
            searchstr = item[-1][:ind]
            #print('II', item[-1], searchstr)
            if searchstr not in searchlist:
                for iitem in masterlist:
                    #print('VV', iitem[-1], searchstr + '0')
                    if iitem[-1].startswith(searchstr + '0'):
                        searchlist.append(searchstr)
                        break
    for sitem in searchlist:
        print('SS', sitem)
    for item in masterlist:
        for sitem in searchlist:
            tname = item[-1]
            if tname.startswith(sitem):
                tname = tname[len(sitem):]
                ind = 0
                while tname[ind] >= '0' and tname[ind] <= '9':
                    ind = ind + 1
                item[-1] = sitem + tname[:ind] + '_' + tname[ind:]
                break

#
# parser for .v files
#
def parse_verilog(filename):
    global masterlist
    global paramnames, modulename
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
            subs = f[1].translate(None,' ').lower()
            if subs[-2:] == ':0':
                subs = subs[:-2]
            if subs.find('(') >= 0 and subs[-1] == ')':
                subs = subs[1:-1]
            if subs[-2:] == '-1':
                subs = subs[:-2]
            else:
                subs = str(int(subs) + 1)
            if subs.find('(') >= 0 and subs[-1] == ')':
                subs = subs[1:-1]
            ind = subs.find('/')
            if ind > 0:
                item = subs[:ind]
                newitem = parammap.get(item)
                if newitem:
                    item = newitem
                subs = 'TDiv#('+item+','+subs[ind+1:]+')'
            else:
                newitem = parammap.get(subs)
                if newitem:
                    subs = newitem
            f[1] = subs
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
            if f[0] == 'module':
                modulename = f[1]
            if f[0] == 'input' or f[0] == 'output' or f[0] == 'inout':
                if len(f) == 2:
                    f = [f[0], '1', f[1]]
                # check for parameterized declarations
                pname = f[1].strip('0123456789/')
                if len(pname) > 0 and pname not in paramnames and pname[:4] != 'TDiv':
                    print('Missing parameter declaration', pname, file=sys.stderr)
                    paramnames.append(pname)
                f[1] = 'Bit#(' + f[1] + ')'
                if f[2] in clocknames:
                    f[1] = 'Clock'
                #print('FF', f, file=sys.stderr)
            masterlist.append(f)
    paramnames.sort()

clock_names = []
def generate_interface(ifname, paramval, ilist, cname):
    global clock_names
    print('(* always_ready, always_enabled *)')
    print('interface ' + ifname + ';')
    for item in ilist:
        if item[0] != 'input' and item[0] != 'output' and item[0] != 'inout' and item[0] != 'interface':
            continue
        if item[0] == 'input':
            if item[1] != 'Clock':
                print('    method Action      '+item[-1].lower()+'('+item[1]+' v);')
        elif item[0] == 'output':
            if item[1] == 'Clock':
                print('    interface Clock     '+item[-1].lower()+';')
                clock_names.append(item)
            else:
                print('    method '+item[1]+'     '+item[-1].lower()+'();')
        elif item[0] == 'inout':
            print('    interface Inout#('+item[1]+')     '+item[-1].lower()+';')
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
            m = re.search('(.+?)(\d+)_(.+)', litem)
            if prevlist != [] and not litem.startswith(currentgroup):
                print('UU', currentgroup, litem, prevlist, file=sys.stderr)
            if m:
                indexname = m.group(2)
                fieldname = m.group(3)
                #print('OO', item[-1], m.groups(), file=sys.stderr)
            else:
                m = re.search('(.+?)_(.+)', litem)
                if not m:
                    newlist.append(item)
                    continue
                if len(m.group(1)) == 1: # if only 1 character prefix, get more greedy
                    m = re.search('(.+)_(.+)', litem)
                indexname = ''
                fieldname = m.group(2)
                #print('OJ', item[-1], m.groups(), file=sys.stderr)
            groupname = m.group(1)
            itemname = groupname + indexname
            if itemname.lower() in ['event']:
                itemname = itemname + '_'
            #fieldname = fieldname + '_'
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
        #print('interface', k, file=sys.stderr)
        for kuse, vuse in sorted(v.items()):
            if kuse == '' or kuse == '0':
                generate_interface(k+paramlist, paramval, vuse, [])
            #else:
                #print('     ', kuse, json.dumps(vuse), file=sys.stderr)

def locate_clocks(item, prefix):
    global clock_params
    pname = prefix + item[-1]
    if item[0] == 'input':
        if item[1] == 'Clock':
            clock_params.append(pname.lower())
    elif item[0] == 'interface':
        temp = commoninterfaces[item[1]].get('0')
        if not temp:
            temp = commoninterfaces[item[1]]['']
        for titem in temp:
             locate_clocks(titem, item[3])

def generate_clocks(item, indent, prefix):
    prefname = prefix + item[-1]
    if item[0] == 'input':
        if item[1] == 'Clock':
            print(indent + 'input_clock '+prefname.lower()+'('+ prefname+') = '+prefname.lower() + ';')
            print(indent + 'input_reset '+prefname.lower()+'_reset() = '+prefname.lower() + '_reset;')
    elif item[0] == 'interface':
        temp = commoninterfaces[item[1]].get('0')
        if not temp:
            temp = commoninterfaces[item[1]]['']
        for titem in temp:
             generate_clocks(titem, '        ', item[3])

def generate_instance(item, indent, prefix, clockedby_arg):
    methodlist = ''
    pname = ''
    if prefix:
        pname = prefix[:-1].lower() + '.'
        if pname == 'event.':
            pname = 'event_.'
    prefname = prefix + item[-1]
    if item[0] == 'input':
        if item[1] != 'Clock':
            print(indent + 'method '+item[-1].lower()+'('+ prefname +')' + clockedby_arg + ' enable((*inhigh*) EN_'+prefname+');')
            methodlist = methodlist + ', ' + pname + item[-1].lower()
    elif item[0] == 'output':
        if item[1] == 'Clock':
            print(indent + 'output_clock '+ item[-1].lower()+ '(' + prefname+');')
        else:
            print(indent + 'method '+ prefname + ' ' + item[-1].lower()+'()' + clockedby_arg + ';')
            methodlist = methodlist + ', ' + pname + item[-1].lower()
    elif item[0] == 'inout':
        print(indent + 'ifc_inout '+item[-1].lower()+'('+ prefname+');')
    elif item[0] == 'interface':
        print(indent + 'interface '+item[1]+'     '+item[2].lower()+';')
        temp = commoninterfaces[item[1]].get('0')
        if not temp:
            temp = commoninterfaces[item[1]]['']
        clockedby_name = ''
        for titem in temp:
             if titem[0] == 'input' and titem[1] == 'Clock':
                 print('PPP', item, titem, file=sys.stderr)
                 clockedby_name = ' clocked_by (' + (item[3]+titem[-1]).lower() + ') reset_by (' + (item[3]+titem[-1]).lower() + '_reset)'
        for titem in temp:
             methodlist = methodlist + generate_instance(titem, '        ', item[3], clockedby_name)
        print('    endinterface')
    return methodlist

def translate_verilog(ifname):
    global paramnames, modulename, clock_names
    global clock_params
    # generate output file
    print('\n/*')
    for item in sys.argv:
        print('   ' + item)
    print('*/\n')
    for item in ['Clocks', 'DefaultValue', 'XilinxCells', 'GetPut']:
        print('import ' + item + '::*;')
    print('')
    paramlist = ''
    for item in paramnames:
        paramlist = paramlist + ', numeric type ' + item
    if paramlist != '':
        paramlist = '#(' + paramlist[2:] + ')'
    paramval = paramlist.replace('numeric type ', '')
    generate_inter_declarations(paramlist, paramval)
    generate_interface(ifname + paramlist, paramval, masterlist, clock_names)
    print('import "BVI" '+modulename + ' =')
    temp = 'module mk' + ifname
    for item in masterlist:
        locate_clocks(item, '')
    if clock_params != []:
        sepstring = '#('
        for item in clock_params:
            temp = temp + sepstring + 'Clock ' + item + ', Reset ' + item + '_reset'
            sepstring = ', '
        temp = temp + ')'
    temp = temp + '(' + ifname + paramval + ');'
    print(temp)
    for item in paramnames:
        print('    let ' + item + ' = valueOf(' + item + ');')
    print('    default_clock clk();')
    print('    default_reset rst();')
    for item in masterlist:
        if item[0] == 'parameter':
            print('    parameter ' + item[1] + ' = ' + item[2] + ';')
    methodlist = ''
    for item in masterlist:
        generate_clocks(item, '    ', '')
    for item in masterlist:
        methodlist = methodlist + generate_instance(item, '    ', '', '')
    if methodlist != '':
        methodlist = '(' + methodlist[2:] + ')'
        print('    schedule '+methodlist + ' CF ' + methodlist + ';')
    print('endmodule')

if __name__=='__main__':
    parser = optparse.OptionParser("usage: %prog [options] arg")
    parser.add_option("-f", "--output", dest="filename", help="write data to FILENAME")
    parser.add_option("-p", "--param", action="append", dest="param")
    parser.add_option("-r", "--remap", action="append", dest="remap")
    parser.add_option("-c", "--clock", action="append", dest="clock")
    (options, args) = parser.parse_args()
    ifname = 'PPS7'
    #print('KK', options, args, file=sys.stderr)
    if options.param:
        for item in options.param:
            item2 = item.split(':')
            if len(item2) == 1:
                if item2[0] not in paramnames:
                    paramnames.append(item2[0])
            else:
                parammap[item2[0]] = item2[1]
                if item2[1] not in paramnames:
                    paramnames.append(item2[1])
    if options.remap:
        for item in options.remap:
            item2 = item.split(':')
            if len(item2) == 2:
                remapmap[item2[0]] = item2[1]
    clocknames = options.clock
    if len(args) != 1:
        print("incorrect number of arguments", file=sys.stderr)
    else:
        if args[0].endswith('.lib'):
            parse_lib(args[0])
        else:
            parse_verilog(args[0])
        masterlist = regroup_items(ifname, masterlist)
        translate_verilog(ifname)
