#! /usr/bin/env python
# Copyright (c) 2013 Quanta Research Cambridge, Inc
# Original author John Ankcorn
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

from __future__ import print_function
import copy, glob, os, sys
import evalexpr, valuemap
NAME_NET_GND = 'net_gnd'
NAME_ASSIGNED = 'pgassign'
SORT_ORDER_UNUSED  = '0:'
SORT_ORDER_NAMES   = '1:'
SORT_ORDER_GND     = '3:'
SORT_ORDER_GENNAME = '5:'
SORT_ORDER_GENWIRE = '6:'
gndsizes = []
gndstr = []
buslists = []
busnames = []
wiredecl = {}
LINE_TYPES = ['BEGIN', 'END', 'PORT', 'BUS_INTERFACE', 'IO_INTERFACE', 'OPTION', 'PARAMETER']

        #tclk = buslists[tbus['BUSLIST']]['INTERNAL_SIGIS_CLK']
        #tconn = tclk.get('ISCONNECTEDTO')
        #tval = titem['ISCONNECTEDTO'] + '[0:0]'
        #if not tconn:
        #    pass
        #else:
        #    if not tconn.startswith(NAME_ASSIGNED):
        #        generated_names.append([tconn])
        #    generated_names[int(tclk['ISCONNECTEDTO'][len(NAME_ASSIGNED):])-1].append(tval)
        #SORT_ORDER_GENNAME = '5:'
        #l = 1
        #for item in generated_names:
        #    print('  wire [' + str(len(item) - 1) + ':0] ' + NAME_ASSIGNED + str(l) + ';', file = outputfile)
        #    l = l + 1

def lookup_param(master, name):
    for item in master['PARAMETER']:
        if item['NAME'] == name:
            return item
    return None

def get_instance(master):
    tname = master.get('INSTANCE')
    if tname:
        return tname
    return master['BEGIN'][0]['NAME']

def parse_file(afilename):
    tmaster = {}
    version = ''
    thismpd = afilename[-4:] == '.mpd'
    saved_tmaster = tmaster
    tmaster['FILENAME'] = afilename
    tmaster['HW_VER'] = ''
    troot, text = os.path.splitext(afilename)
    for item in LINE_TYPES:
        tmaster[item] = []
    if not thismpd:
        tmaster['BEGIN'].append({'NAME': os.path.basename(troot)})
    print('opening', afilename)
    data = open(afilename).read()
    # iterate through all lines in file
    for citem in data.split('\n'):
        while(citem and (citem[0] == ' ' or citem[0] == '\t')):
            # strip off leading whitespace
            citem = citem[1:]
        if len(citem) == 0 or citem[0] == '#':
            continue
        itemsplit = []
        tlist = {}
        line_name = ''
        lastind = 0
        parendepth = 0
        append_item = True
        # split input line into comma separated 'attr=val' list
        for thisind in range(len(citem)):
            ch = citem[thisind]
            if ch == '(':
                parendepth = parendepth + 1
            elif ch == ')':
                parendepth = parendepth - 1
            elif ch == ',' and parendepth == 0:
                itemsplit.append(citem[lastind:thisind])
                lastind = thisind + 1
        itemsplit.append(citem[lastind:])
        # now iterate through all items in list of 1 line
        for ind in range(len(itemsplit)):
            item = itemsplit[ind].strip()
            equals_index = item.find('=')
            space_index = item.find(' ')
            vname = 'NAME'
            if ind == 0:
                # syntax for processing first item on a line is a bit special
                line_name = item
                if space_index > 0:
                    line_name = item[0:space_index].upper()
                if equals_index < 0:
                    equals_index = space_index
                    if not thismpd and line_name == 'BEGIN':
                        temp = item[equals_index+1:].strip()
                        tmaster[line_name].append({'NAME': temp})
                        tmaster = parse_file(temp + version + '.mpd')
                        component_definitions.append(tmaster)
                        append_item = False
                    if not thismpd and line_name == 'END':
                        # reevaluate all the items in the file we just included
                        # (the PARAMETER items may impact the evaluation results)
                        evaluate_symbolic(tmaster)
                        tmaster = saved_tmaster
                elif space_index > 0:
                    temp = item[space_index:equals_index].strip()
                    if (line_name != 'BUS_INTERFACE' or temp != 'BUS') and (line_name != 'IO_INTERFACE' or temp != 'IO_IF'):
                        # in '.mpd' file, there is an extra keyword
                        vname = 'VALUE'
                        tlist['NAME'] = temp
                    for tempitem in tmaster[line_name]:
                        if tempitem['NAME'].upper() == temp.upper():
                            tlist = tempitem
                            tlist['IS_INSTANTIATED'] = 'TRUE'
                            append_item = False
                            break
                    if line_name == 'PORT' and not thismpd:
                        vname = 'ISCONNECTEDTO'
            elif equals_index > 0:
                vname = item[0:equals_index].strip().upper()
            else:
                print('Error: missing "=" in attribute assignment', citem)
                continue
            item = item[equals_index+1:].strip()
            if item == '""':
                item = ''
            tlist[vname] = item
        if line_name == 'PORT' and tlist.get('BUS') and tlist.get('VALUE') == '' and tlist.get('SIGIS') == 'CLK':
            tlist['VALUE'] = 'INTERNAL_SIGIS_CLK'
        # now that we have gathered all the attributes into tlist, perform local processing
        tname = tlist.get('NAME')
        tval = tlist.get('VALUE')
        if line_name == 'OPTION' and (tname == 'IPTYPE' or tname == 'BUS_STD'):
            tmaster[tname] = tval
        if line_name == 'PARAMETER':
            if tname == 'INSTANCE':
                tmaster[tname] = tval
                continue
            if tname == 'HW_VER':
                tmaster[tname] = '_v' + tval.replace('.', '_')
                continue
            if tname == 'VERSION':
                version = '_v' + tval.replace('.', '_')
        if append_item and line_name == 'BUS_INTERFACE':
            tprefix = ''
            if tlist.get('BUS_TYPE') == 'SLAVE':
                tprefix = 'S_'
            elif tlist.get('BUS_TYPE') == 'MASTER':
                tprefix = 'M_'
            tlist['BUSPREFIX'] = tprefix
            buslists.append({})
            busnames.append([tmaster, tlist])
            tlist['BUSLIST'] = len(buslists) - 1
        if line_name == 'PORT' and tlist.get('BUS'):
            if tval == '' and tlist.get('SIGIS') == 'CLK':
                tbus['VALUE'] = 'INTERNAL_SIGIS_CLK'
            for tbus in tmaster['BUS_INTERFACE']:
                if tbus['NAME'] == tlist['BUS']:
                    buslists[tbus['BUSLIST']][tval] = tlist
                    if tlist.get('SIGIS') == 'CLK':
                        buslists[tbus['BUSLIST']]['INTERNAL_SIGIS_CLK'] = tlist
        if append_item:
            # now append the tlist item onto the correct list for this file and linetype
            tmaster[line_name].append(tlist)
    #########################################
    for item in valuemap.VALMAP:
        tlist = lookup_param(tmaster, item)
        if tlist:
            tlist['VALUE']=valuemap.VALMAP[tlist['NAME']]
            tlist['CHANGEDBY']='SYSTEM'
    print('leaving', afilename)
    return tmaster

def evaluate_symbolic(tmaster):
    # evaluate/bind all symbolic expressions in a line from mpd/mhs file
    for aname in LINE_TYPES:
        for titem in tmaster[aname]:
            item = titem.get('VEC')
            if item and item[0] == '[':
                cind = item.find(':')
                rind = item.find(']')
                titem['MSB'] = evalexpr.eval_expression(item[1:cind].strip(), tmaster, lookup_param)
                titem['LSB'] = evalexpr.eval_expression(item[cind+1:rind].strip(), tmaster, lookup_param)
            item = titem.get('ISVALID')
            if item:
                titem['EVALISVALID'] = evalexpr.eval_expression(item, tmaster, lookup_param)
            item = titem.get('CONTRIBUTION')
            if item:
                titem['EVALCONTRIBUTION'] = evalexpr.eval_expression(item, tmaster, lookup_param)

def pin_hasval(tmaster, titem):
    dname = titem.get('DIR')
    return dname and (dname != 'IO' or titem.get('THREE_STATE') != 'TRUE')

def commalist(itemlist):
    for i in range(len(itemlist)-1):
        print(itemlist[i] + ',', file = outputfile)
    print(itemlist[len(itemlist) - 1], file = outputfile)

def output_arglist(tmaster, ismhs, istop, afilename):
    global outputfile, topname
    if afilename is not None:
        outputfile = open(afilename, 'w')
    tname = get_instance(tmaster)
    if not ismhs:
        tname = topname + tname + '_wrapper'
    if istop:
        print('//-----------------------------------------------------------------------------', file = outputfile)
        print('// ' + tname + '.v', file = outputfile)
        print('//-----------------------------------------------------------------------------', file = outputfile)
        if not ismhs:
            print('\n(* x_core_info = "' + tmaster['BEGIN'][0]['NAME'] + tmaster['HW_VER'] + '" *)', file = outputfile)
            if tmaster['BEGIN'][0]['NAME'] == 'processing_system7':
                print(valuemap.P7TEXT, file = outputfile)

    foo = []
    for titem in tmaster['PORT']:
        if pin_hasval(tmaster, titem):
            foo.append('    ' + titem['NAME'])
    print('\nmodule ' + tname + '\n  (', file = outputfile)
    commalist(foo)
    print('  );', file = outputfile)
    for titem in tmaster['PORT']:
        if pin_hasval(tmaster, titem):
            t = ''
            l = titem.get('MSB')
            if l:
                t = ' [' + l + ':' + titem['LSB'] + ']'
            print('  ' + {'O': 'output', 'I': 'input', 'IO': 'inout'}[titem['DIR']] + t + ' ' + titem['NAME'] + ';', file = outputfile)

def output_parameter(tmaster, afilename):
    output_arglist(tmaster, False, True, afilename)
    if tmaster['BEGIN'][0]['NAME'] == 'processing_system7':
        print('  ' + valuemap.P7TEXT, file = outputfile)
    foo = []
    for titem in tmaster['PARAMETER']:
        if titem.get('TYPE') != 'NON_HDL':
            delim = ''
            if titem.get('DT') == 'STRING':
                delim = '"'
            vitem = titem['VALUE']
            vlen = len(vitem) - 2
            if vlen > 0:
                if vitem[0:2] == '0x':
                    vitem = str(vlen*4) + "'h" + vitem[2:]
                if vitem[0:2] == '0b':
                    vitem = str(vlen) + "'b" + vitem[2:]
            foo.append('      .' + titem['NAME'] + ' ( ' + delim + vitem + delim + ' )')
    print('\n  ' + tmaster['BEGIN'][0]['NAME'] + '\n    #(', file = outputfile)
    commalist(foo)
    print('    )', file = outputfile)
    output_instance(tmaster, True)
    print('\nendmodule\n', file = outputfile)

def setwire(name, size, direction, aforce):
    if name == 'hdmidisplay_0_interrupt':
        print('SSS', name, size, direction, aforce)
    if not wiredecl.get(name):
        wiredecl[name] = {}
        wiredecl[name] = {'SIZE':size, 'FORCE': False}
    if wiredecl[name]['SIZE'] != size:
        aforce = True
    if wiredecl[name]['SIZE'] is None or (size is not None and int(wiredecl[name]['SIZE']) < int(size)):
        wiredecl[name]['SIZE'] = size
    wiredecl[name][direction] = True
    wiredecl[name]['FORCE'] = aforce or wiredecl[name]['FORCE']

def bind_wires(item):
    for titem in item['PORT']:
        tbus = None
        tval = titem.get('VALUE')
        twidth = titem.get('MSB')
        if titem.get('EVALISVALID') != 'FALSE' and item.get('IPTYPE') != 'BUS':
            for zbus in item['BUS_INTERFACE']:
                if zbus['NAME'] == titem.get('BUS'):
                    tbus = zbus['EVALBUSBIND']
        if tval == 'INTERNAL_SIGIS_CLK':
            tval = ''
        l = titem.get('ISCONNECTEDTO')
        if l:
            ind = l.find('[')
            if ind > 0:
                twidth = l[ind+1:-1]
                l = l[:ind]
                nind = twidth.find(':')
                if nind > 0:
                    twidth = twidth[:nind]
        elif tbus:
            l = tbus['VALUE'] + '_' + tval
        if l is not None and l != '':
            if l == 'hdmidisplay_0_interrupt':
                print('LLLLL', item['BEGIN'], l, twidth, titem, tbus)
            setwire(l, twidth, titem['DIR'], False)

def bind_value(item):
    for titem in item['PORT']:
        #if not pin_hasval(item, titem):
        #    continue
        tbus = None
        aitem = None
        tval = titem.get('VALUE')
        tmsb = titem.get('MSB')
        tlsb = titem.get('lSB')
        tmsbv = 0
        poffset = 0
        if tmsb:
            tmsbv = int(tmsb)
        poffset = tmsbv + 1
        if titem.get('EVALISVALID') != 'FALSE' and item.get('IPTYPE') != 'BUS':
            for zbus in item['BUS_INTERFACE']:
                if zbus['NAME'] == titem.get('BUS'):
                    tbus = zbus['EVALBUSBIND']
                    aitem = buslists[tbus['BUSLIST']][tval]
        l = titem.get('ISCONNECTEDTO')
        if l is not None:
            witem = wiredecl[l]
            if l == 'hdmidisplay_0_interrupt':
                print('LLLKKKK', item['BEGIN'], l, tmsb, titem, tbus, witem)
            if not tmsb and witem['SIZE'] != None:
                titem['ISCONNECTEDTO'] = titem['ISCONNECTEDTO'] + '[0]'
            if (witem.get('I') is None or witem.get('O') is None) and not witem['FORCE'] and not witem.get('TOPLEVELSIGNAL'):
                titem['ISCONNECTEDTO'] = ''
            continue
        l = ''
        if tbus:
            pcontrib = aitem.get('EVALCONTRIBUTION')
            if pcontrib:
                poffset = int(pcontrib)
            poffset = poffset * tbus['BUSOFFSET']
            l = tbus['VALUE'] + '_' + tval
            tlower = ''
            if tmsb or tlsb is not None:
                if tlsb is None:
                    tlsb = 0
                tlower = ':' + str(int(tlsb) + poffset)
            if wiredecl[l]['SIZE'] is not None and int(wiredecl[l]['SIZE']) != tmsbv+poffset:
                wiredecl[l]['FORCE'] = True
                l = l + '[' + str(tmsbv+poffset) + tlower + ']'
            elif (wiredecl[l].get('I') is None or wiredecl[l].get('O') is None) and not wiredecl[l]['FORCE']:
                l = ''
        if l == '' and titem.get('DIR') == 'I':
            # set all unassigned inputs to GND
            if tmsb is not None:
                tmsbv = tmsbv + 1
            l = NAME_NET_GND + str(tmsbv)
            if tmsbv not in gndsizes:
                gndsizes.append(tmsbv)
                twidth = None
                if tmsbv != 0:
                    twidth = str(tmsbv - 1)
                setwire(l, twidth, titem['DIR'], True)
                gndstr.append(l)
            if tmsbv == 1:
                l = l + '[0:0]'
        titem['ISCONNECTEDTO'] = l

def output_instance(tmaster, toplevel):
    foo = []
    for titem in tmaster['PORT']:
        if pin_hasval(tmaster, titem):
            if toplevel:
                l = titem['NAME']
            else:
                l = titem['ISCONNECTEDTO']
            foo.append('      .' + titem['NAME'] + ' ( ' + l + ' )')
    print('    ' + get_instance(tmaster) + ' (', file = outputfile)
    commalist(foo)
    print('    );', file = outputfile)

def main():
    global component_definitions, outputfile, topname
    component_definitions = []
    if len(sys.argv) != 2:
        print(sys.argv[0] + ' <inputfilename>', file = outputfile)
        sys.exit(1)
    topname, item =  os.path.splitext(os.path.basename(sys.argv[1]))
    topname = topname + '_'
    top_item = parse_file(sys.argv[1])

    evaluate_symbolic(top_item)
    mhsfile = sys.argv[1][-4:] == '.mhs'
    if not mhsfile:
        output_parameter(top_item, 'foo.out')
    else:
        for item in component_definitions:
            for titem in item['BUS_INTERFACE']:
                if titem.get('EVALISVALID') == 'FALSE':
                    continue
                if item.get('BUS_STD') == 'AXIPT':
                    if titem.get('VALUE') or not item.get('INSTANCE'):
                        print('Error: bogus BUS definition')
                    titem['VALUE'] = item['INSTANCE']
                else:
                    for aitem in component_definitions:
                        for atitem in aitem['BUS_INTERFACE']:
                            if aitem.get('INSTANCE') == titem['VALUE'] and atitem['BUS_TYPE'] == titem['BUS_TYPE']:
                                titem['EVALBUSBIND'] = atitem
                #print('BBB', item.get('BUS_STD'), item.get('INSTANCE'), titem)
                tname = titem['BUS_STD'] + titem['BUS_TYPE']
                if not item.get(tname):
                    item[tname] = 0
                titem['BUSOFFSET'] = item[tname]
                item[tname] = item[tname] + 1

        for item in component_definitions:
            bind_wires(item)
        for titem in top_item['PORT']:
            temp = wiredecl.get(titem['NAME'])
            if temp:
                print('tople', titem['NAME'])
                temp['TOPLEVELPIN'] = True
            temp = titem.get('ISCONNECTEDTO')
            if temp:
                temp = wiredecl.get(temp)
                if temp:
                    temp['TOPLEVELSIGNAL'] = True
                    temp['FORCE'] = True

        for item in component_definitions:
            bind_value(item)
            output_parameter(item, 'foo.' + get_instance(item) + '.out')
            outputfile.close()

        output_arglist(top_item, True, True, 'foo.out')

        print('\n  // Internal signals\n', file = outputfile)
        for wname, witem in sorted(wiredecl.iteritems()):
            if wname == 'hdmidisplay_0_interrupt':
                print('WWWW', witem)
            if ((witem.get('I') and witem.get('O')) or witem['FORCE']) and not witem.get('TOPLEVELPIN'):
                l = witem['SIZE']
                if l != None:
                    l = '[' + str(l) + ':0] '
                else:
                    l = ''
                print('  wire ' + l + wname + ';', file = outputfile)

        print('\n  // Internal assignments\n', file = outputfile)
        for titem in top_item['PORT']:
            if titem.get('DIR') == 'O':
                print('  assign ' + titem['NAME'] + ' = ' + titem['ISCONNECTEDTO'] + ';', file = outputfile)
        #l = 1
        #for item in generated_names:
        #    j = len(item) - 1
        #    for val in item:
        #        print('  assign ' + NAME_ASSIGNED + str(l) + '[' + str(j) + ':' + str(j) + '] = ' + val + ';', file = outputfile)
        #        j = j - 1
        for sitem in sorted(gndstr):
            item = int(sitem[len(NAME_NET_GND):])
            l = '  assign ' + sitem
            if item == 0:
                item = 1
            else:
                l = l + '[' + str(item-1) + ':0]'
            print(l + ' = ' + str(item) + "'b" + '0' * item + ';', file = outputfile)
        print('\n  (* CORE_GENERATION_INFO = "processing_system7_0,processing_system7,{C_PRESET_FPGA_PARTNUMBER = xc7z020clg484-1,C_PRESET_FPGA_SPEED = -1,C_PRESET_GLOBAL_CONFIG = Default,C_PRESET_GLOBAL_DEFAULT = powerup}" *)', file = outputfile)
        for item in component_definitions:
            print('\n  (* BOX_TYPE = "user_black_box" *)', file = outputfile)
            print('  ' + topname + get_instance(item) + '_wrapper', file = outputfile)
            output_instance(item, False)
        print('\nendmodule', file = outputfile)
        for item in component_definitions:
            output_arglist(item, False, False, None)
            print('endmodule', file = outputfile)
        print('', file = outputfile)

if __name__ == '__main__':
    main()
