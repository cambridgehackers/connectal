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
import valuemap
import evalexpr

###### main ######
outputfile = None

def lookup_param(master, name):
    thislist = master.get('PARAMETER')
    if thislist:
        for item in thislist:
            if item['NAME'] == name:
                return item
    return None

def get_instance(master):
    tname = master.get('INSTANCE')
    if tname:
        return tname
    return master['BEGIN'][0]['NAME']

def parse_file(afilename, tmaster, axifullbus, wirelist):
    ipflag = False
    busflag = False
    localaxi = None
    version = ''
    thismpd = afilename[-4:] == '.mpd'
    saved_tmaster = tmaster
    tmaster['FILENAME'] = afilename
    tmaster['HW_VER'] = ''
    troot, text = os.path.splitext(afilename)
    tmaster['BEGIN'] = []
    if not thismpd:
        tmaster['BEGIN'].append({'NAME': os.path.basename(troot)})
    print('opening', afilename)
    data = open(afilename).read()
    # iterate through all lines in file
    for citem in data.split('\n'):
        if len(citem) == 0 or citem[0] == '#':
            continue
        itemsplit = []
        tlist = {}
        line_name = ''
        lastind = 0
        parendepth = 0
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
            iind = item.find('=')
            if ind == 0:
                # syntax for processing first item on a line is a bit special
                nind = item.find(' ')
                vname = 'NAME'
                line_name = item
                if nind > 0:
                    line_name = item[0:nind].upper()
                if iind < 0:
                    iind = nind
                    if not thismpd and line_name == 'BEGIN':
                        temp = item[iind+1:].strip()
                        tmaster[line_name].append({'NAME': temp})
                        tmaster, tempaxi = parse_file(temp + version + '.mpd', {}, axifullbus, wirelist)
                        if tempaxi:
                            localaxi = tempaxi
                        component_definitions.append(tmaster)
                        line_name = 'BEGIN_UNUSED'
                    if not thismpd and line_name == 'END':
                        eval_itemlist(tmaster)
                        tmaster = saved_tmaster
                elif nind > 0:
                    temp = item[nind:iind].strip()
                    if (line_name != 'BUS_INTERFACE' or temp != 'BUS') and (line_name != 'IO_INTERFACE' or temp != 'IO_IF'):
                        # in '.mpd' file, there is an extra keyword
                        vname = 'VALUE'
                        tlist['NAME'] = temp
                    if tmaster.get(line_name):
                        for tempitem in tmaster[line_name]:
                            if tempitem['NAME'] == temp:
                                tlist = tempitem
                                tlist['IS_INSTANTIATED'] = 'TRUE'
                                break
                    if line_name == 'PORT' and not thismpd:
                        vname = 'ISCONNECTEDTO'
            elif iind > 0:
                vname = item[0:iind].strip().upper()
            else:
                print('Error: missing "=" in attribute assignment', citem)
                continue
            item = item[iind+1:].strip()
            if item == '""':
                item = ''
            tlist[vname] = item
            if vname == 'ISCONNECTEDTO':
                if not wirelist.get(item):
                    wirelist[item] = []
                wirelist[item].append([tmaster, tlist])
        # now that we have gathered all the attributes into tlist, perform local processing
        tname = tlist.get('NAME')
        tval = tlist.get('VALUE')
        if line_name == 'OPTION':
            if tname == 'IPTYPE' and tval == 'BUS':
                ipflag = True
            if tname == 'BUS_STD' and tval == 'AXI':
                busflag = True
            if ipflag and busflag:
                # we have located the AXI bus definition component
                localaxi = tmaster
        if line_name == 'PARAMETER':
            if tname == 'INSTANCE':
                tmaster['INSTANCE'] = tval
                continue
            if tname == 'HW_VER':
                tmaster['HW_VER'] = '_v' + tval.replace('.', '_')
                continue
            if tname == 'VERSION':
                version = '_v' + tval.replace('.', '_')
        if line_name == 'PORT' and localaxi == tmaster and tval:
            # create index for AXI bus wires
            if tval != '' and not axifullbus.get(tname[0:2] + tval):
                axifullbus[tname[0:2] + tval] = tlist
            if tlist.get('SIGIS') == 'CLK':
                axifullbus[tname[0:2] + 'INTERNAL_SIGIS_CLK'] = tlist
        # now append the tlist item onto the correct list for this file and linetype
        if not tmaster.get(line_name):
            tmaster[line_name] = []
        if not tlist.get('IS_INSTANTIATED'):
            tmaster[line_name].append(tlist)
    #########################################
    for item in valuemap.VALMAP:
        tlist = lookup_param(tmaster, item)
        if tlist:
            #print('CHHHH', tmaster['BEGIN'], tlist['NAME'])
            tlist['VALUE']=valuemap.VALMAP[tlist['NAME']]
            tlist['CHANGEDBY']='SYSTEM'
    return tmaster, localaxi

def eval_item(arg_list, tmaster):
    # evaluate/bind all symbolic expressions in a line from mpd/mhs file
    if arg_list.get('VEC'):
        item = arg_list['VEC']
        if item[0] == '[':
            cind = item.find(':')
            rind = item.find(']')
            arg_list['MSB'] = evalexpr.eval_expression(item[1:cind].strip(), tmaster, lookup_param)
            arg_list['LSB'] = evalexpr.eval_expression(item[cind+1:rind].strip(), tmaster, lookup_param)
    item = arg_list.get('ISVALID')
    if item:
        arg_list['ISVALID'] = evalexpr.eval_expression(item, tmaster, lookup_param)
    item = arg_list.get('CONTRIBUTION')
    if item:
        arg_list['CONTRIBUTION'] = evalexpr.eval_expression(item, tmaster, lookup_param)

def eval_itemlist(tmaster):
    for arg_list in tmaster['PORT']:
        eval_item(arg_list, tmaster)
    if tmaster.get('BUS_INTERFACE'):
        for arg_list in tmaster['BUS_INTERFACE']:
            eval_item(arg_list, tmaster)

def pin_hasval(titem):
    dname = titem.get('DIR')
    return dname and (dname != 'IO' or titem.get('THREE_STATE') != 'TRUE')

def output_arglist(tmaster, ismhs, istop):
    tname = get_instance(tmaster)
    if not ismhs:
        tname = 'echo_' + tname + '_wrapper'
    if istop:
        print('//-----------------------------------------------------------------------------', file = outputfile)
        print('// ' + tname + '.v', file = outputfile)
        print('//-----------------------------------------------------------------------------\n', file = outputfile)
        if not ismhs:
            print('(* x_core_info = "' + tmaster['BEGIN'][0]['NAME'] + tmaster['HW_VER'] + '" *)', file = outputfile)
            if tmaster['BEGIN'][0]['NAME'] == 'processing_system7':
                print(valuemap.P7TEXT, file = outputfile)

    print('\nmodule ' + tname + '\n  (', file = outputfile)
    l = None
    for arg_list in tmaster['PORT']:
        dname = arg_list.get('DIR')
        if pin_hasval(arg_list):
            if l:
                print(l + ',', file = outputfile)
            l = '    ' + arg_list['NAME']
    if l:
        print(l, file = outputfile)
    print('  );', file = outputfile)
    DIRNAMES = {'O': 'output', 'I': 'input', 'IO': 'inout'}
    for arg_list in tmaster['PORT']:
        dname = arg_list.get('DIR')
        if pin_hasval(arg_list):
            t = DIRNAMES[dname]
            l = arg_list.get('MSB')
            #print('l', l, arg_list)
            if l:
                t = t + ' [' + l + ':' + arg_list['LSB'] + ']'
            print('  ' + t + ' ' + arg_list['NAME'] + ';', file = outputfile)

def output_parameter(tmaster):
    output_arglist(tmaster, False, True)
    if tmaster['BEGIN'][0]['NAME'] == 'processing_system7':
        print('  ' + valuemap.P7TEXT, file = outputfile)
    print('\n  ' + tmaster['BEGIN'][0]['NAME'] + '\n    #(', file = outputfile)
    l = None
    for arg_list in tmaster['PARAMETER']:
        if arg_list.get('TYPE') != 'NON_HDL' and arg_list.get('ISVALID') != 'FALSE':
            delim = ''
            if arg_list.get('DT') == 'STRING':
                delim = '"'
            vitem = arg_list['VALUE']
            vlen = len(vitem) - 2
            if vlen > 0:
                if vitem[0:2] == '0x':
                    vitem = str(vlen*4) + "'h" + vitem[2:]
                if vitem[0:2] == '0b':
                    vitem = str(vlen) + "'b" + vitem[2:]
            if l:
                print(l + ',', file = outputfile)
            l = '      .' + arg_list['NAME'] + ' ( ' + delim + vitem + delim + ' )'
    if l:
        print(l, file = outputfile)
    print('    )', file = outputfile)
    output_instance(tmaster, True)
    print('\nendmodule\n', file = outputfile)

def output_instance(tmaster, toplevel):
    l = None
    print('    ' + get_instance(tmaster) + ' (', file = outputfile)
    for arg_list in tmaster['PORT']:
        if pin_hasval(arg_list):
            if l:
                print(l + ',', file = outputfile)
            l = '      .' + arg_list['NAME'] + ' ( '
            if toplevel:
                l = l + arg_list['NAME']
            elif arg_list.get('ISCONNECTEDTO'):
                l = l + arg_list['ISCONNECTEDTO']
            elif arg_list.get('IS_INSTANTIATED') == 'TRUE':
                l = l + arg_list['VALUE']
            l = l + ' )'
    if l:
        print(l, file = outputfile)
    print('    );', file = outputfile)

def bus_lookup(tmaster, titem):
    if titem.get('BUS') and titem.get('ISVALID') != 'FALSE' and tmaster.get('BUS_INTERFACE'):
        for bitem in tmaster['BUS_INTERFACE']:
            if bitem.get('ISVALID') != 'FALSE' and bitem['NAME'] == titem['BUS']:
                tprefix = ''
                if bitem['BUS_TYPE'] == 'SLAVE':
                    tprefix = 'M_'
                elif bitem['BUS_TYPE'] == 'MASTER':
                    tprefix = 'S_'
                return tprefix, bitem
    return '', None


def main():
    global component_definitions, outputfile
    component_definitions = []
    generated_names = []
    axiitem = None
    axibus = []
    gndsizes = []
    gndstr = []
    axifullbus = {}
    wirelist = {}
    if len(sys.argv) != 2:
        print(sys.argv[0] + ' <inputfilename>', file = outputfile)
        sys.exit(1)
    top_item, axiitem = parse_file(sys.argv[1], {}, axifullbus, wirelist)

    eval_itemlist(top_item)
    mhsfile = sys.argv[1][-4:] == '.mhs'
    if not mhsfile:
        outputfile = open('foo.out', 'w')
        output_parameter(top_item)
    else:
        for item in component_definitions:
            for titem in item['BUS_INTERFACE']:
                if titem.get('ISVALID') != 'FALSE' and titem.get('BUS_STD') == 'AXI':
                    if not axiitem.get(titem['BUS_TYPE']):
                        axiitem[titem['BUS_TYPE']] = 0
                    titem['BUS_OFFSET'] = axiitem[titem['BUS_TYPE']]
                    axiitem[titem['BUS_TYPE']] = axiitem[titem['BUS_TYPE']] + 1
            for titem in item['PORT']:
                tval = titem.get('VALUE')
                tprefix, tbus = bus_lookup(item, titem)
                tval = tprefix + tval
                if titem.get('ISVALID') == 'FALSE' or not tbus:
                    continue
                if tval not in axifullbus:
                    if titem.get('SIGIS') == 'CLK':
                        tclk = axifullbus[tval[0:2] + 'INTERNAL_SIGIS_CLK']
                        tconn = tclk.get('ISCONNECTEDTO')
                        tval = titem['ISCONNECTEDTO'] + '[0:0]'
                        temp = '[0:0] ' + titem['ISCONNECTEDTO']
                        if not tconn:
                            tclk['ISCONNECTEDTO'] = tval
                        else:
                            if not tconn.startswith('pgassign'):
                                generated_names.append([tconn])
                                tclk['ISCONNECTEDTO'] = 'pgassign' + str(len(generated_names))
                            generated_names[int(tclk['ISCONNECTEDTO'][8:])-1].append(tval)
                    else:
                        print('Error: signal not found in bus', titem)
                elif tval:
                    # gather a list of AXI bus signal names that were actually used
                    if tval not in axibus and axiitem != item:
                        axibus.append(tval)
            if True:
                outputfile = open('foo.' + get_instance(item) + '.out', 'w')
                output_parameter(item)
                outputfile.close()
                #sys.exit(1)

        outputfile = open('foo.out', 'w')
        output_arglist(top_item, True, True)
        for key, witem in wirelist.items():
            #print('WWWWWWW', key, len(witem))
            tchanged = False
            tlast = None
            if len(witem) == 1:
                for item, titem in witem:
                    titem['ISCONNECTEDTO'] = ''
            for item, titem in witem:
                tprefix, tbus = bus_lookup(item, titem)
                tvec = titem.get('MSB') is not None or (tbus is not None and tbus['BUS_OFFSET'] != 0)
                if tlast is not None and tlast != tvec:
                    tchanged = True
                tlast = tvec
                #print('WWWWWWW', key, len(witem), titem['NAME'], tchanged, tvec)
            if tchanged:
                for item, titem in witem:
                    if titem.get('MSB'):
                        titem['ISCONNECTEDTO'] = titem['ISCONNECTEDTO'] + '[0:0]'
                    else:
                        titem['ISCONNECTEDTO'] = titem['ISCONNECTEDTO'] + '[0]'

        generated_wires = []
        for item in component_definitions:
            for titem in item['PORT']:
                if titem.get('DIR') == 'O' and titem.get('ISCONNECTEDTO'):
                    #print('OOOOO', titem)
                    generated_wires.append(titem['ISCONNECTEDTO'])

        for item in component_definitions:
            for titem in item['PORT']:
                tname = titem['NAME']
                tval = titem.get('VALUE')
                tiscon = titem.get('ISCONNECTEDTO')
                tmsb = titem.get('MSB')
                if tmsb:
                    tmsbv = int(tmsb)
                else:
                    tmsbv = 0
                tprefix, tbus = bus_lookup(item, titem)
                tval = tprefix + tval
                aitem = axifullbus.get(tval)
                l = None
                if titem.get('ISVALID') == 'FALSE' or item == axiitem:
                    aitem = None
                if titem.get('IS_INSTANTIATED') == 'TRUE':
                    continue
                if item == axiitem and not titem.get('BUS') and tname[0] + '_' + tval in axibus:
                    # only instantiate AXI bus wires that are actually used
                    l = get_instance(item) + '_' + tname[0] + '_' + tval
                    if titem.get('MSB') and int(titem.get('MSB')) == 0 and not titem.get('CONTRIBUTION'):
                        l = l + '[0:0]'
                elif tbus and tbus.get('BUS_TYPE') == 'SLAVE' and pin_hasval(titem):
                    poffset = tmsbv + 1
                    pcontrib = aitem.get('CONTRIBUTION')
                    if pcontrib:
                        poffset = int(pcontrib)
                    poffset = poffset * tbus['BUS_OFFSET']
                    pend = str(poffset)
                    if tmsb:
                        pend = str(tmsbv+poffset) + ':' + str(int(titem['LSB'])+poffset)
                    l = tbus['VALUE'] + '_' + tval + '[' + pend + ']'
                elif tbus and tbus.get('BUS_TYPE') == 'MASTER':
                    msbtemp = aitem.get('MSB')
                    if msbtemp and tmsb:
                        if tmsb != msbtemp:
                            msbtemp = tmsb
                        elif aitem.get('CONTRIBUTION'):
                            msbtemp = None
                    if msbtemp is not None:
                        tval = tval + '[' + str(msbtemp)
                        if int(aitem['LSB']) != int(msbtemp):
                            tval = tval + ':' + str(aitem['LSB'])
                        tval = tval + ']'
                    l = tbus['VALUE'] + '_' + tval
                elif titem.get('DIR') == 'I':
                    # set all unassigned inputs to GND
                    if tmsb:
                        tmsbv = int(tmsb) + 1
                    else:
                        tmsbv = 0
                    l = 'net_gnd' + str(tmsbv)
                    if tmsbv not in gndsizes:
                        gndsizes.append(tmsbv)
                        gndstr.append(l)
                    if tmsbv == 1:
                        l = l + '[0:0]'
                if l:
                    titem['VALUE'] = l
                    titem['IS_INSTANTIATED'] = 'TRUE'

        print('\n  // Internal signals\n', file = outputfile)
        for item in sorted(axibus):
             titem = axifullbus.get(item)
             if titem:
                 tval = titem.get('MSB')
                 if not tval:
                     tval = 0
                 print('  wire [' + str(tval) + ':0] ' + get_instance(axiitem) + '_' + item + ';', file = outputfile)
        for item in sorted(gndsizes):
            l = '  wire'
            if item != 0:
                l = l + ' [' + str(item-1) + ':0]'
            print(l + ' net_gnd' + str(item) + ';', file = outputfile)
        l = 1
        for item in generated_names:
            print('  wire [' + str(len(item) - 1) + ':0] pgassign' + str(l) + ';', file = outputfile)
            l = l + 1
        for item in sorted(generated_wires):
            ind = item.find('[')
            if ind > 0:
                item = '[0:0] ' + item[:ind]
            print('  wire ' + item + ';', file = outputfile)
        print('\n  // Internal assignments\n', file = outputfile)
        for titem in top_item['PORT']:
            if titem.get('DIR') == 'O':
                print('  assign ' + titem['NAME'] + ' = ' + titem['ISCONNECTEDTO'] + ';', file = outputfile)
        l = 1
        for item in generated_names:
            j = len(item) - 1
            for val in item:
                print('  assign pgassign' + str(l) + '[' + str(j) + ':' + str(j) + '] = ' + val + ';', file = outputfile)
                j = j - 1
        for sitem in sorted(gndstr):
            item = int(sitem[7:])
            l = '  assign ' + sitem
            if item == 0:
                item = 1
            else:
                l = l + '[' + str(item-1) + ':0]'
            print(l + ' = ' + str(item) + "'b" + '0' * item + ';', file = outputfile)
        print('\n  (* CORE_GENERATION_INFO = "processing_system7_0,processing_system7,{C_PRESET_FPGA_PARTNUMBER = xc7z020clg484-1,C_PRESET_FPGA_SPEED = -1,C_PRESET_GLOBAL_CONFIG = Default,C_PRESET_GLOBAL_DEFAULT = powerup}" *)', file = outputfile)
        for item in component_definitions:
            tname = get_instance(item)
            print('\n  (* BOX_TYPE = "user_black_box" *)', file = outputfile)
            print('  echo_' + tname + '_wrapper', file = outputfile)
            output_instance(item, False)
        print('\nendmodule', file = outputfile)
        for item in component_definitions:
            output_arglist(item, False, False)
            print('endmodule', file = outputfile)
        print('', file = outputfile)

if __name__ == '__main__':
    main()
