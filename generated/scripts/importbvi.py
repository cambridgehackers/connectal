#!/usr/bin/env python3
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
import copy, json, optparse, os, sys, re, tokenize
#names of tokens: tokenize.tok_name

masterlist = []
parammap = {}
paramnames = []
ifdefmap = {}
conditionalcf = {}
clock_names = []
deleted_interface = []
commoninterfaces = {}
tokgenerator = 0
clock_params = []
reset_params = []
toknum = 0
tokval = 0
modulename = ''

class PinType(object):
    def __init__(self, mode, type, name, origname):
        self.mode = mode
        self.type = type
        self.name = name.lower()
        self.origname = origname
        self.comment = ''
        self.separator = ''
        #print('PNN', self.mode, self.type, self.name, self.origname)
#
# parser for .lib files
#
def parsenext():
    global toknum, tokval
    while True:
        toknum, tokval, _, _, _ = next(tokgenerator)
        if toknum != tokenize.NL and toknum != tokenize.NEWLINE:
            break
    #print('Token:', toknum, tokval)
    if toknum == tokenize.ENDMARKER:
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
    global masterlist, modulename
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
                    if plist == {}:
                        paramlist['attr'].append([paramstr])
                    else:
                        paramlist['attr'].append([paramstr, plist])
                if paramname == 'cell' and paramstr == options.cell:
                    #print('CC', paramstr)
                    modulename = paramstr
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
                            ptemp = 'Bit#(1)'
                            if options.clock and k in options.clock:
                                ptemp = 'Clock'
                            if options.reset and k in options.reset:
                                ptemp = 'Reset'
                        else:
                            ptemp = 'Bit#(' + str(int(v[1])+1) + ')'
                        ttemp = PinType(v[0], ptemp, k, k)
                        if v[2] != {}:
                            ttemp.comment = v[2]
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
    if tokval != 'library':
        sys.exit(1)
    validate_token(toknum == tokenize.NAME)
    parseparam()
    parse_item()
    searchlist = []
    for item in masterlist:
        ind = item.name.find('1')
        if ind > 0:
            searchstr = item.name[:ind]
            #print('II', item.name, searchstr)
            if searchstr not in searchlist:
                for iitem in masterlist:
                    #print('VV', iitem.name, searchstr + '0')
                    if iitem.name.startswith(searchstr + '0'):
                        searchlist.append(searchstr)
                        break
    for item in masterlist:
        for sitem in searchlist:
            tname = item.name
            if tname.startswith(sitem):
                tname = tname[len(sitem):]
                ind = 0
                while tname[ind] >= '0' and tname[ind] <= '9' and ind < len(tname) - 1:
                    ind = ind + 1
                item.name = sitem + tname[:ind] + item.separator + tname[ind:]
                break

#
# parser for .v files
#
def processline(line, phase):
    global masterlist
    global paramnames, modulename
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
        m = re.match('([^:]+):([^:]+)', subs)
        if m:
            i1 = int(m.group(1))
            i2 = int(m.group(2))
            subs = '%d' % (max(i1,i2) - min(i1,i2) + 1)
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
    #print("ARR", f, file=sys.stderr)
    if len(f) > 0:
        if f[0][-1] == ';':
            return True
        if f[-1][-1] == ';':
            f[-1] = f[-1][:-1]
        if f[0] == 'module':
            modulename = f[1]
        if f[0] == 'input' or f[0] == 'output' or f[0] == 'inout':
            if len(f) == 2:
                f = [f[0], '', '1', f[1]]
            if len(f) == 3:
                f = [f[0], '', f[1], f[2]]
            # check for parameterized declarations
            pname = f[2].strip('0123456789/')
            if len(pname) > 0 and pname not in paramnames and pname[:4] != 'TDiv':
                print('Missing parameter declaration', pname, file=sys.stderr)
                paramnames.append(pname)
            f[2] = 'Bit#(' + f[2] + ')'
            if options.delete and f[3] in options.delete:
                return False
            if options.clock and f[3] in options.clock:
                f[2] = 'Clock'
            if options.reset and f[3] in options.reset:
                f[2] = 'Reset'
            #print('FF', f, file=sys.stderr)
        elif f[0].startswith('input') or f[0].startswith('output') or f[0].startswith('inout'):
            if len(f) == 3:
                f = [f[0].split()[0], f[0].split()[1], f[1], f[2]]
            # check for parameterized declarations
            pname = f[2].strip('0123456789/')
            if len(pname) > 0 and pname not in paramnames and pname[:4] != 'TDiv':
                print('Missing parameter declaration', pname, file=sys.stderr)
                paramnames.append(pname)
            f[2] = 'Bit#(' + f[2] + ')'
            if options.delete and f[3] in options.delete:
                return False
            if options.clock and f[3] in options.clock:
                f[2] = 'Clock'
            if options.reset and f[3] in options.reset:
                f[2] = 'Reset'
            #print('FE', f, file=sys.stderr)
        elif phase == 2:
            return True
        if phase == 2:
            itemfound = False
            for item in masterlist:
                if item.origname == f[3]:
                    item.mode = f[0]
                    if options.clock and f[3] in options.clock:
                        item.type = 'Clock'
                    elif options.reset and f[3] in options.reset:
                        item.type = 'Reset'
                    else:
                        item.type = f[2]
                    itemfound = True
                    break
            if not itemfound:
                print('UNK not found', f)
            return False
        if len(f) == 4:
            #print('FFDDDDD3', f, file=sys.stderr)
            masterlist.append(PinType(f[0], f[2], f[3], f[3]))
        elif len(f) == 2:
            #print('FFDDDDD2', f, file=sys.stderr)
            masterlist.append(PinType(f[0], '', f[1], f[1]))
        else:
            #print('FFDDDDDE', f, file=sys.stderr)
            masterlist.append(PinType('UNK', 'FOO', f[0], f[0]))
    return False

def parse_verilog(filename):
    indata = open(filename).read().expandtabs().split('\n')
    phase = 1
    for line in indata:
        if processline(line, phase):
            if phase == 2:
               break
            phase = 2

def generate_condition(interfacename):
    global ifdefmap
    for k, v in ifdefmap.items():
        if interfacename in v:
            print('`ifdef', k, file=options.outfile)
            return k
    return None

def generate_interface(interfacename, paramlist, paramval, ilist, cname):
    global clock_names, deleted_interface
    if interfacename in options.notdef:
        return
    cflag = generate_condition(interfacename)
    print('(* always_ready, always_enabled *)', file=options.outfile)
    methodfound = False
    for item in ilist:
        #print("GG", item.name, item.type, item.mode)
        if item.mode == 'input' and (item.type != 'Clock' and item.type != 'Reset'):
            methodfound = True
        elif item.mode == 'output':
            methodfound = True
        elif item.mode == 'inout':
            methodfound = True
        elif item.mode == 'interface':
            methodfound = True
    if not methodfound:
        deleted_interface.append(interfacename)
        return
    print('interface ' + interfacename + paramlist + ';', file=options.outfile)
    for item in ilist:
        if item.mode != 'input' and item.mode != 'output' and item.mode != 'inout' and item.mode != 'interface':
            continue
        if item.mode == 'input':
            if item.type != 'Clock' and item.type != 'Reset':
                print('    method Action      '+item.name+'('+item.type+' v);', file=options.outfile)
        elif item.mode == 'output':
            if item.type == 'Clock' and item.type != 'Reset':
                print('    interface Clock     '+item.name+';', file=options.outfile)
                clock_names.append(item)
            else:
                print('    method '+item.type+'     '+item.name+'();', file=options.outfile)
        elif item.mode == 'inout':
            print('    interface Inout#('+item.type+')     '+item.name+';', file=options.outfile)
        elif item.mode == 'interface' and item.type not in deleted_interface:
            cflag2 = generate_condition(item.type)
            print('    interface '+item.type+ paramval +'     '+item.name+';', file=options.outfile)
            if cflag2:
                print('`endif', file=options.outfile)
    print('endinterface', file=options.outfile)
    if cflag:
        print('`endif', file=options.outfile)

def fixname(arg):
    titem = arg.replace('ZZ', 'ZZA')
    titem = titem.replace('I2C', 'ZZB')
    titem = titem.replace('P2F', 'ZZC')
    titem = titem.replace('F2P', 'ZZD')
    titem = titem.replace('ev128', 'ZZE')
    titem = titem.replace('ev1', 'ZZF')
    titem = titem.replace('l2', 'ZZG')
    titem = titem.replace('l0', 'ZZH')
    titem = titem.replace('l1', 'ZZI')
    return titem

def goback(arg):
    titem = arg.replace('ZZB', 'I2C')
    titem = titem.replace('ZZC', 'P2F')
    titem = titem.replace('ZZD', 'F2P')
    titem = titem.replace('ZZA', 'ZZ')
    titem = titem.replace('ZZE', 'ev128')
    titem = titem.replace('ZZF', 'ev1')
    titem = titem.replace('ZZG', 'l2')
    titem = titem.replace( 'ZZH','l0')
    titem = titem.replace( 'ZZI','l1')
    return titem

def regroup_items(masterlist):
    global paramnames, commoninterfaces
    paramnames.sort()
    masterlist = sorted(masterlist, key=lambda item: item.type if item.mode == 'parameter' else item.name)
    newlist = []
    currentgroup = ''
    prevlist = []
    for item in masterlist:
        if item.mode != 'input' and item.mode != 'output' and item.mode != 'inout':
            newlist.append(item)
            #print("DD", item.name)
        else:
            litem = item.origname
            titem = fixname(litem)
            #m = re.search('(.+?)(\d+)_(.+)', litem)
            m = re.search('(.+?)(\d+)(_?)(.+)', titem)
            #print('OA', titem)
            separator = '_'
            indexname = ''
            skipParse = False;
            if prevlist != [] and not litem.startswith(currentgroup):
                print('UU', currentgroup, litem, prevlist, file=sys.stderr)
            if options.factor:
                for tstring in options.factor:
                    if len(litem) > len(tstring) and litem.startswith(tstring):
                        groupname = tstring
                        fieldname = litem[len(tstring):]
                        if fieldname[0] == '_':
                            fieldname = fieldname[1:]
                            separator = '_'
                        else:
                            separator = ''
                        m = None
                        skipParse = True
                        #print('OM', titem, groupname, fieldname, separator)
                        break
            if m:
                skipcheck = False
                for checkitem in options.notfactor:
                    if litem.startswith(checkitem):
                        skipcheck = True
                if skipcheck:
                    newlist.append(item)
                    #print('OB', item.name)
                    continue
                groupname = goback(m.group(1))
                indexname = goback(m.group(2))
                separator = goback(m.group(3))
                fieldname = goback(m.group(4))
                #print('OO', item.name, [groupname, indexname, fieldname], file=sys.stderr)
            elif separator != '' and skipParse != True:
                m = re.search('(.+?)_(.+)', litem)
                if not m:
                    newlist.append(item)
                    #print('OD', item.name)
                    continue
                if len(m.group(1)) == 1: # if only 1 character prefix, get more greedy
                    m = re.search('(.+)_(.+)', litem)
                #print('OJ', item.name, m.groups(), file=sys.stderr)
                fieldname = m.group(2)
                groupname = m.group(1)

            skipcheck = False
            for checkitem in options.notfactor:
                if litem.startswith(checkitem):
                    skipcheck = True
            if skipcheck:
                newlist.append(item)
                #print('OI', item.name, file=sys.stderr)
                continue
            itemname = (groupname + indexname).lower()
            if itemname in ['event']:
                itemname = itemname + '_'
            interfacename = options.ifprefix[0].upper() + options.ifprefix[1:].lower() + groupname[0].upper() + groupname[1:].lower()
            if not commoninterfaces.get(interfacename):
                commoninterfaces[interfacename] = {}
            if not commoninterfaces[interfacename].get(indexname):
                commoninterfaces[interfacename][indexname] = []
                t = PinType('interface', interfacename, itemname, groupname+indexname+separator)
                #print('OZ', interfacename, itemname, groupname+indexname+separator, file=sys.stderr)
                t.separator = separator
                newlist.append(t)
            #print('OH', itemname, separator, file=sys.stderr)
            foo = copy.copy(item)
            foo.origname = fieldname
            lfield = fieldname.lower()
            if lfield in ['assert', 'do']:
                lfield = 'zz' + lfield      # prefix prohibited names with 'zz'
            foo.name = lfield
            commoninterfaces[interfacename][indexname].append(foo)
    return newlist

def generate_inter_declarations(paramlist, paramval):
    global commoninterfaces
    for k, v in sorted(commoninterfaces.items()):
        #print('interface', k, file=sys.stderr)
        for kuse, vuse in sorted(v.items()):
            if kuse == '' or kuse == '0':
                generate_interface(k, paramlist, paramval, vuse, [])
            #else:
                #print('     ', kuse, json.dumps(vuse), file=sys.stderr)

def locate_clocks(item, prefix):
    global clock_params, reset_params
    pname = prefix + item.name
    if item.mode == 'input':
        if item.type == 'Clock':
            clock_params.append(pname.lower())
            reset_params.append(pname.lower() + '_reset')
        if item.type == 'Reset':
            reset_params.append(pname.lower())
    elif item.mode == 'interface':
        temp = commoninterfaces[item.type].get('0')
        if not temp:
            temp = commoninterfaces[item.type].get('')
        if not temp:
            print('Missing interface definition', item.type, commoninterfaces[item.type])
            return
        for titem in temp:
            locate_clocks(titem, item.origname)

def generate_clocks(item, indent, prefix):
    prefname = prefix + item.origname
    if item.mode == 'input':
        if item.type == 'Clock':
            print(indent + 'input_clock '+prefname.lower()+'('+ prefname+') = '+prefname.lower() + ';', file=options.outfile)
            print(indent + 'input_reset '+prefname.lower()+'_reset() = '+prefname.lower() + '_reset; /* from clock*/', file=options.outfile)
        if item.type == 'Reset':
            print(indent + 'input_reset '+prefname.lower()+'('+ prefname +') = '+prefname.lower() + ';', file=options.outfile)
    elif item.mode == 'interface':
        temp = commoninterfaces[item.type].get('0')
        if not temp:
            temp = commoninterfaces[item.type].get('')
        if not temp:
            print('Missing interface clock', item.type, commoninterfaces[item.type])
            return
        for titem in temp:
             generate_clocks(titem, '        ', item.origname)

def generate_instance(item, indent, prefix, clockedby_arg):
    global deleted_interface
    methodlist = ''
    pname = ''
    if prefix:
        pname = prefix.lower()
        if pname[-1] == '_':
            pname = pname[:-1]
        pname = pname + '.'
        if pname == 'event.':
            pname = 'event_.'
    prefname = prefix + item.origname
    if item.mode == 'input':
        if item.type != 'Clock' and item.type != 'Reset':
            print(indent + 'method '+item.name.lower()+'('+ prefname +')' + clockedby_arg + ' enable((*inhigh*) EN_'+prefname+');', file=options.outfile)
            methodlist = methodlist + ', ' + pname + item.name.lower()
    elif item.mode == 'output':
        if item.type == 'Clock':
            print(indent + 'output_clock '+ item.name.lower()+ '(' + prefname+');', file=options.outfile)
        elif item.type == 'Reset':
            print(indent + 'output_reset '+ item.name.lower()+ '(' + prefname+');', file=options.outfile)
        else:
            print(indent + 'method '+ prefname + ' ' + item.name.lower()+'()' + clockedby_arg + ';', file=options.outfile)
            methodlist = methodlist + ', ' + pname + item.name.lower()
    elif item.mode == 'inout':
        print(indent + 'ifc_inout '+item.name.lower()+'('+ prefname+');', file=options.outfile)
    elif item.mode == 'interface':
        if item.type in deleted_interface:
            return ''
        cflag = generate_condition(item.type)
        print(indent + 'interface '+item.type+'     '+item.name.lower()+';', file=options.outfile)
        baseitem = commoninterfaces[item.type].get('0')
        if not baseitem:
            baseitem = commoninterfaces[item.type].get('')
        if not baseitem:
            print('Missing ifc', item.type)
            return ''
        clockedby_name = ''
        for titem in baseitem:
            #print("BB", titem.mode, titem.type, titem.name)
            if titem.mode == 'input' and titem.type == 'Clock':
                clockedby_name = ' clocked_by (' + (item.origname+titem.name).lower() + ') reset_by (' + (item.origname+titem.name).lower() + '_reset)'
        templist = ''
        for titem in baseitem:
            templist = templist + generate_instance(titem, '        ', item.origname, clockedby_name)
        if cflag:
            if not conditionalcf.get(cflag):
                conditionalcf[cflag] = ''
            conditionalcf[cflag] = conditionalcf[cflag] + templist
        else:
            methodlist = methodlist + templist
        print('    endinterface', file=options.outfile)
        if cflag:
            print('`endif', file=options.outfile)
    return methodlist

def generate_bsv():
    global paramnames, modulename, clock_names
    global clock_params, reset_params, options
    # generate output file
    print('\n/*', file=options.outfile)
    for item in sys.argv:
        print('   ' + item, file=options.outfile)
    print('*/\n', file=options.outfile)
    for item in ['Clocks', 'DefaultValue', 'XilinxCells', 'GetPut', 'AxiBits']:
        print('import ' + item + '::*;', file=options.outfile)
    print('', file=options.outfile)
    paramlist = ''
    for item in paramnames:
        paramlist = paramlist + ', numeric type ' + item
    if paramlist != '':
        paramlist = '#(' + paramlist[2:] + ')'
    paramval = paramlist.replace('numeric type ', '')
    generate_inter_declarations(paramlist, paramval)
    generate_interface(options.ifname, paramlist, paramval, masterlist, clock_names)
    print('import "BVI" '+modulename + ' =', file=options.outfile)
    temp = 'module mk' + options.ifname
    for item in masterlist:
        locate_clocks(item, '')
    if clock_params != [] or reset_params != []:
        sepstring = '#('
        for item in clock_params:
            temp = temp + sepstring + 'Clock ' + item
            sepstring = ', '
        for item in reset_params:
            temp = temp + sepstring + 'Reset ' + item
        temp = temp + ')'
    temp = temp + '(' + options.ifname + paramval + ');'
    print(temp, file=options.outfile)
    for item in paramnames:
        print('    let ' + item + ' = valueOf(' + item + ');', file=options.outfile)
    print('    default_clock clk();', file=options.outfile)
    print('    default_reset rst();', file=options.outfile)
    #for item in masterlist:
    #    if item.mode == 'parameter':
    #        print('    parameter ' + item.type + ' = ' + item.name + ';', file=options.outfile)
    if options.export:
        for item in options.export:
            colonind = item.find(':')
            if colonind > 0:
                print('    parameter ' + item[:colonind] + ' = ' + item[colonind+1:] + ';', file=options.outfile)
    methodlist = ''
    for item in masterlist:
        generate_clocks(item, '    ', '')
    for item in masterlist:
        methodlist = methodlist + generate_instance(item, '    ', '', '')
    if methodlist != '':
        methodlist = methodlist[2:]
        if conditionalcf != {}:
            for k, v in sorted(conditionalcf.items()):
                mtemp = '(' + methodlist + v + ')'
                print('`ifdef', k, file=options.outfile)
                print('    schedule '+mtemp + ' CF ' + mtemp + ';', file=options.outfile)
                print('`else', file=options.outfile)
        methodlist = '(' + methodlist + ')'
        print('    schedule '+methodlist + ' CF ' + methodlist + ';', file=options.outfile)
        if conditionalcf != {}:
            print('`endif', file=options.outfile)
    print('endmodule', file=options.outfile)

if __name__=='__main__':
    parser = optparse.OptionParser("usage: %prog [options] arg")
    parser.add_option("-o", "--output", dest="filename", help="write data to FILENAME")
    parser.add_option("-p", "--param", action="append", dest="param")
    parser.add_option("-f", "--factor", action="append", dest="factor")
    parser.add_option("-c", "--clock", action="append", dest="clock")
    parser.add_option("-r", "--reset", action="append", dest="reset")
    parser.add_option("-d", "--delete", action="append", dest="delete")
    parser.add_option("-e", "--export", action="append", dest="export")
    parser.add_option("--notdef", action="append", dest="notdef")
    parser.add_option("-i", "--ifdef", action="append", dest="ifdef")
    parser.add_option("-n", "--notfactor", action="append", dest="notfactor")
    parser.add_option("-C", "--cell", dest="cell")
    parser.add_option("-P", "--ifprefix", dest="ifprefix")
    parser.add_option("-I", "--ifname", dest="ifname")
    (options, args) = parser.parse_args()
    print('KK', options, args, file=sys.stderr)
    if options.filename is None or len(args) == 0 or options.ifname is None or options.ifprefix is None:
        print('Missing "--o" option, missing input filenames, missing ifname or missing ifprefix.  Run " importbvi.py -h " to see available options')
        sys.exit(1)
    options.outfile = open(options.filename, 'w')
    if options.notfactor == None:
        options.notfactor = []
    if options.notdef == None:
        options.notdef = []
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
    if options.ifdef:
        for item in options.ifdef:
            item2 = item.split(':')
            ifdefmap[item2[0]] = item2[1:]
            print('III', ifdefmap, file=sys.stderr)
    if len(args) != 1:
        print("incorrect number of arguments", file=sys.stderr)
    else:
        if args[0].endswith('.lib'):
            parse_lib(args[0])
        else:
            parse_verilog(args[0])
        masterlist = regroup_items(masterlist)
        generate_bsv()
