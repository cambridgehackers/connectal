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
    for item in master['PARAMETER']:
        if item['NAME'] == name:
            return item
    return None

def bus_lookup(tmaster, titem):
    global component_definitions
    if titem.get('BUS') and titem.get('EVALISVALID') != 'FALSE':
        for tbus in tmaster['BUS_INTERFACE']:
            if tbus.get('EVALISVALID') != 'FALSE' and tbus['NAME'] == titem['BUS']:
                for item in component_definitions:
                    if item.get('IPTYPE') == 'BUS' and item['BUS_STD'] == tbus['BUS_STD']:
                        for zitem in item['BUS_INTERFACE']:
                            if zitem['BUS_TYPE'] != tbus['BUS_TYPE']:
                                return zitem
    return None
    

def get_instance(master):
    tname = master.get('INSTANCE')
    if tname:
        return tname
    return master['BEGIN'][0]['NAME']

def parse_file(afilename, wirelist):
    tmaster = {}
    localaxi = None
    version = ''
    thismpd = afilename[-4:] == '.mpd'
    saved_tmaster = tmaster
    tmaster['FILENAME'] = afilename
    tmaster['HW_VER'] = ''
    troot, text = os.path.splitext(afilename)
    for item in ['BEGIN', 'END', 'PORT', 'BUS_INTERFACE', 'IO_INTERFACE', 'OPTION', 'PARAMETER']:
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
                        tmaster, tempaxi = parse_file(temp + version + '.mpd', wirelist)
                        if tempaxi:
                            localaxi = tempaxi
                        component_definitions.append(tmaster)
                        append_item = False
                    if not thismpd and line_name == 'END':
                        # reevaluate all the items in the file we just included
                        # (the PARAMETER items may impact the evaluation results)
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
                                append_item = False
                                break
                    if line_name == 'PORT' and not thismpd:
                        vname = 'ISCONNECTEDTO'
                        if not wirelist.get(item):
                            wirelist[item] = []
                        wirelist[item].append([tmaster, tlist])
            elif iind > 0:
                vname = item[0:iind].strip().upper()
            else:
                print('Error: missing "=" in attribute assignment', citem)
                continue
            item = item[iind+1:].strip()
            if item == '""':
                item = ''
            tlist[vname] = item
        if line_name == 'PORT' and tlist.get('BUS') and tlist.get('VALUE') == '' and tlist.get('SIGIS') == 'CLK':
            tlist['VALUE'] = 'INTERNAL_SIGIS_CLK'
        # now that we have gathered all the attributes into tlist, perform local processing
        tname = tlist.get('NAME')
        tval = tlist.get('VALUE')
        if line_name == 'OPTION':
            if tname == 'IPTYPE' or tname == 'BUS_STD':
                tmaster[tname] = tval
            if tmaster.get('IPTYPE') == 'BUS' and tmaster.get('BUS_STD') == 'AXIPT':
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
        if append_item and line_name == 'BUS_INTERFACE':
            tprefix = ''
            if tlist['BUS_TYPE'] == 'SLAVE':
                tprefix = 'S_'
            elif tlist['BUS_TYPE'] == 'MASTER':
                tprefix = 'M_'
            tlist['BUSPREFIX'] = tprefix
            tlist['BUSLIST'] = {}
        if line_name == 'PORT' and tlist.get('BUS'):
            if tval == '' and tlist.get('SIGIS') == 'CLK':
                tbus['VALUE'] = 'INTERNAL_SIGIS_CLK'
            for tbus in tmaster['BUS_INTERFACE']:
                if tbus['NAME'] == tlist['BUS']:
                    #if not tbus['BUSLIST'].get(tval):
                    tbus['BUSLIST'][tval] = tlist
                    if tlist.get('SIGIS') == 'CLK':
                        tbus['BUSLIST']['INTERNAL_SIGIS_CLK'] = tlist
        if append_item:
            # now append the tlist item onto the correct list for this file and linetype
            tmaster[line_name].append(tlist)
    #########################################
    for item in valuemap.VALMAP:
        tlist = lookup_param(tmaster, item)
        if tlist:
            #print('CHHHH', tmaster['BEGIN'], tlist['NAME'])
            tlist['VALUE']=valuemap.VALMAP[tlist['NAME']]
            tlist['CHANGEDBY']='SYSTEM'
    print('leaving', afilename)
    return tmaster, localaxi

def eval_itemlist(tmaster):
    # evaluate/bind all symbolic expressions in a line from mpd/mhs file
    for aname in ['PORT', 'BUS_INTERFACE']:
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
        if arg_list.get('TYPE') != 'NON_HDL' and arg_list.get('EVALISVALID') != 'FALSE':
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
            elif arg_list.get('IS_INSTANTIATED') == 'TRUE' and arg_list['VALUE'] != 'INTERNAL_SIGIS_CLK':
                l = l + arg_list['VALUE']
            l = l + ' )'
    if l:
        print(l, file = outputfile)
    print('    );', file = outputfile)

def main():
    global component_definitions, outputfile
    component_definitions = []
    generated_names = []
    axiitem = None
    axibus = []
    gndsizes = []
    gndstr = []
    wirelist = {}
    if len(sys.argv) != 2:
        print(sys.argv[0] + ' <inputfilename>', file = outputfile)
        sys.exit(1)
    top_item, axiitem = parse_file(sys.argv[1], wirelist)

    eval_itemlist(top_item)
    mhsfile = sys.argv[1][-4:] == '.mhs'
    if not mhsfile:
        outputfile = open('foo.out', 'w')
        output_parameter(top_item)
    else:
        for item in component_definitions:
            for titem in item['BUS_INTERFACE']:
                if titem.get('EVALISVALID') == 'FALSE':
                    continue
                if item.get('BUS_STD') == 'AXIPT':
                    if titem.get('VALUE') or not item.get('INSTANCE'):
                        print('Error: bogus BUS definition')
                    titem['VALUE'] = item['INSTANCE']
                if titem.get('BUS_STD') == 'AXIPT':
                    tname = titem['BUS_STD'] + titem['BUS_TYPE']
                    if not item.get(tname):
                        item[tname] = 0
                    titem['BUSOFFSET'] = item[tname]
                    item[tname] = item[tname] + 1
                    print('BBB', item['BEGIN'][0]['NAME'], titem['NAME'], titem['BUSOFFSET'], titem['BUS_TYPE'], len(titem['BUSLIST']))
            for titem in item['PORT']:
                tbus = bus_lookup(item, titem)
                if titem.get('EVALISVALID') == 'FALSE' or not tbus:
                    continue
                tval = titem.get('VALUE')
                if tval == 'INTERNAL_SIGIS_CLK':
                    tclk = tbus['BUSLIST']['INTERNAL_SIGIS_CLK']
                    tconn = tclk.get('ISCONNECTEDTO')
                    tval = titem['ISCONNECTEDTO'] + '[0:0]'
                    #print('CCCCCCCC', tconn, tclk, titem['NAME'], tval)
                    if not tconn:
                        tclk['ISCONNECTEDTO'] = tval
                    else:
                        if not tconn.startswith('pgassign'):
                            generated_names.append([tconn])
                            tclk['ISCONNECTEDTO'] = 'pgassign' + str(len(generated_names))
                        generated_names[int(tclk['ISCONNECTEDTO'][8:])-1].append(tval)
                else:
                    tval = tbus['BUSPREFIX'] + tval
                    # gather a list of AXI bus signal names that were actually used
                    if tval not in axibus and axiitem != item:
                        axibus.append(tval)
            outputfile = open('foo.' + get_instance(item) + '.out', 'w')
            output_parameter(item)
            outputfile.close()

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
                tbus = bus_lookup(item, titem)
                #print('item, tbus', titem, tbus)
                tvec = titem.get('MSB') is not None or (tbus is not None and tbus['BUSOFFSET'] != 0)
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
                    print('OOOOO', titem)
                    generated_wires.append(titem['ISCONNECTEDTO'])

        for item in component_definitions:
            for titem in item['PORT']:
                if titem.get('IS_INSTANTIATED') == 'TRUE':
                    continue
                aitem = None
                tname = titem['NAME']
                tval = titem.get('VALUE')
                tiscon = titem.get('ISCONNECTEDTO')
                tmsb = titem.get('MSB')
                tmsbv = 0
                if tmsb:
                    tmsbv = int(tmsb)
                tbus = bus_lookup(item, titem)
                if tbus:
                    aitem = tbus['BUSLIST'][tval]
                    tval = tbus['BUSPREFIX'] + tval
                l = None
                if titem.get('EVALISVALID') == 'FALSE' or item == axiitem:
                    aitem = None
                if tbus and (tbus.get('BUS_TYPE') == 'MASTER' or item == axiitem) and pin_hasval(titem):
                    poffset = tmsbv + 1
                    if tbus and not aitem:
                        #print('Error: missing slave item', tbus, titem, aitem, item == axiitem)
                        continue
                    pcontrib = aitem.get('EVALCONTRIBUTION')
                    if pcontrib:
                        poffset = int(pcontrib)
                    poffset = poffset * tbus['BUSOFFSET']
                    pend = str(poffset)
                    if tmsb:
                        pend = str(tmsbv+poffset) + ':' + str(int(titem['LSB'])+poffset)
                    l = tbus['VALUE'] + '_' + tval + '[' + pend + ']'
                elif tbus and tbus.get('BUS_TYPE') == 'SLAVE':
                    msbtemp = aitem.get('MSB')
                    if aitem.get('EVALCONTRIBUTION'):
                        msbtemp = int(aitem['EVALCONTRIBUTION']) - 1
                    if msbtemp:
                        if not tmsb:
                            msbtemp = 0
                        elif int(tmsb) != int(msbtemp):
                            msbtemp = tmsb
                        else:
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
        for aname in sorted(axibus):
             for item in component_definitions:
                 if item.get('IPTYPE') != 'BUS' or item['BUS_STD'] != 'AXIPT':
                     continue
                 for litem in item['BUS_INTERFACE']:
                     for bkeyval,bitem in litem['BUSLIST'].items():
                         if litem['BUSPREFIX'] + bkeyval == aname:
                             tval = bitem.get('MSB')
                             if not tval:
                                 tval = 0
                             print('  wire [' + str(tval) + ':0] ' + get_instance(axiitem) + '_' + aname + ';', file = outputfile)
                             break
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
