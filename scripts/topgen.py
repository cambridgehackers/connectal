#!/usr/bin/python
## Copyright (c) 2013-2014 Quanta Research Cambridge, Inc.

## Permission is hereby granted, free of charge, to any person
## obtaining a copy of this software and associated documentation
## files (the "Software"), to deal in the Software without
## restriction, including without limitation the rights to use, copy,
## modify, merge, publish, distribute, sublicense, and/or sell copies
## of the Software, and to permit persons to whom the Software is
## furnished to do so, subject to the following conditions:

## The above copyright notice and this permission notice shall be
## included in all copies or substantial portions of the Software.

## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
## EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
## MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
## NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
## BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
## ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
## CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
## SOFTWARE.

import os, sys, shutil, string
import argparse
import util

argparser = argparse.ArgumentParser("Generate Top.bsv for an project.")
argparser.add_argument('--project-dir', help='project directory')
argparser.add_argument('--interface', help='exported interface declaration', action='append')
argparser.add_argument('--importfiles', help='added imports', action='append')
argparser.add_argument('--portname', help='added portal names to enum list', action='append')
argparser.add_argument('--wrapper', help='exported wrapper interfaces', action='append')
argparser.add_argument('--proxy', help='exported proxy interfaces', action='append')

topTemplate='''
import Vector::*;
import Portal::*;
import CtrlMux::*;
import HostInterface::*;
%(generatedImport)s

`ifndef PinType
`define PinType Empty
`endif
typedef `PinType PinType;

typedef enum {%(enumList)s} IfcNames deriving (Eq,Bits);

module mkConnectalTop
`ifdef IMPORT_HOSTIF
       #(HostType host)
`endif
       (%(moduleParam)s);
   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();
%(portalInstantiate)s

   Vector#(%(portalCount)s,StdPortal) portals;
%(portalList)s
   let ctrl_mux <- mkSlaveMux(portals);
   interface interrupt = getInterruptVector(portals);
   interface slave = ctrl_mux;
   interface masters = %(portalMaster)s;
%(exportedInterfaces)s
endmodule : mkConnectalTop
%(exportedNames)s
'''

def addPortal(name):
    global portalCount
    portalList.append('   portals[%(count)s] = %(name)s.portalIfc;' % {'count': portalCount, 'name': name})
    portalCount = portalCount + 1

class iReq:
    def __init__(self):
        self.inst = ''
        self.args = []

def instMod(args, modname, modext, constructor, tparam):
    if not modname:
        return
    pmap['tparam'] = tparam
    pmap['modname'] = modname + modext
    tstr = 'S2H'
    if modext:
        if modext == 'Proxy':
            tstr = 'H2S'
        args = modname + tstr
        if modext != 'Proxy':
            args += ', l%(userIf)s'
        enumList.append(modname + tstr)
        addPortal('l%(modname)s' % pmap)
    pmap['constr'] = pmap['constructor']
    if not pmap['constructor'] or modext:
        pmap['constr'] = 'mk' + pmap['modname']
    if modext:
        portalInstantiate.append(('   %(modname)s%(tparam)s l%(modname)s <- %(constr)s(' + args + ');') % pmap)
    else:
        if not instantiateRequest.get(pmap['modname']):
            instantiateRequest[pmap['modname']] = iReq()
            instantiateRequest[pmap['modname']].inst = '   %(modname)s%(tparam)s l%(modname)s <- %(constr)s(%%s);' % pmap
        instantiateRequest[pmap['modname']].args.append(args % pmap)
    if pmap['modname'] not in instantiatedModules:
        instantiatedModules.append(pmap['modname'])
    importfiles.append(modname)

def parseParam(pitem):
    p = pitem.split(':')
    pr = p[1].split('.')
    pmap = {'name': p[0], 'usermod': pr[0], 'userIf': p[1], 'tparam': '', 'xparam': '', 'uparam': '', 'constructor': ''}
    if len(p) > 2 and p[2]:
        pmap['uparam'] = p[2] + ', '
    if len(p) > 3 and p[3]:
        pmap['xparam'] = '#(' + p[3] + ')'
    if len(p) > 4:
        pmap['constructor'] = p[4]
    return pmap

if __name__=='__main__':
    options = argparser.parse_args()

    if not options.project_dir:
        print "topgen: --project-dir option missing"
        sys.exit(1)
    project_dir = os.path.abspath(os.path.expanduser(options.project_dir))
    topFilename = project_dir + '/Top.bsv'
    print 'Writing Top:', topFilename
    userFiles = []
    portalInstantiate = []
    instantiateRequest = {}
    portalList = []
    portalCount = 0
    instantiatedModules = []
    importfiles = []
    exportedNames = ['export mkConnectalTop;']
    if options.importfiles:
        importfiles = options.importfiles
        for item in options.importfiles:
             exportedNames.append('export %s::*;' % item)
    enumList = []
    if options.portname:
        enumList = options.portname
    interfaceList = []
    if not options.proxy:
        options.proxy = []
    if not options.wrapper:
        options.wrapper = []
    if not options.interface:
        options.interface = []

    for pitem in options.proxy:
        pmap = parseParam(pitem)
        instMod('', pmap['name'], 'Proxy', '', '')
        argstr = pmap['uparam'] + 'l%(name)sProxy.ifc'
        if pmap['uparam'] and pmap['uparam'][0] == '/':
            argstr = 'l%(name)sProxy.ifc, ' + pmap['uparam'][1:-2]
        instMod(argstr, pmap['usermod'], '', '', pmap['xparam'])
    for pitem in options.wrapper:
        pmap = parseParam(pitem)
        if pmap['usermod'] not in instantiatedModules:
            instMod(pmap['uparam'], pmap['usermod'], '', '', pmap['xparam'])
    for key in instantiatedModules:
        temp = instantiateRequest.get(key)
        if temp:
            portalInstantiate.append(temp.inst % ','.join(temp.args))
    for pitem in options.wrapper:
        pmap = parseParam(pitem)
        instMod('', pmap['name'], 'Wrapper', '', '')
    for pitem in options.interface:
        p = pitem.split(':')
        interfaceList.append('   interface %s = l%s;' % (p[0], p[1]))

    memory_flag = 'MemServer' in instantiatedModules
    topsubsts = {'enumList': ','.join(enumList),
                 'generatedImport': '\n'.join(['import %s::*;' % p for p in importfiles]),
                 'portalInstantiate' : '\n'.join(portalInstantiate),
                 'portalList': '\n'.join(portalList),
                 'portalCount': portalCount,
                 'exportedInterfaces' : '\n'.join(interfaceList),
                 'exportedNames' : '\n'.join(exportedNames),
                 'portalMaster' : 'lMemServer.masters' if memory_flag else 'nil',
                 'moduleParam' : 'ConnectalTop#(PhysAddrWidth,DataBusWidth,`PinType,`NumberOfMasters)' \
                     if memory_flag else 'StdConnectalTop#(PhysAddrWidth)'
                 }
    print 'TOPFN', topFilename
    top = util.createDirAndOpen(topFilename, 'w')
    top.write(topTemplate % topsubsts)
    top.close()
