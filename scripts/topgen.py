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
import MemPortal::*;
import Connectable::*;
import MemreadEngine::*;
import MemwriteEngine::*;
import MemTypes::*;
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
%(pipeInstantiate)s

%(portalInstantiate)s
%(connectInstantiate)s

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

portalTemplate = '''   let portalEnt_%(count)s <- mkMemPortal(extend(pack(%(enumVal)s)), l%(ifcName)s.portalIfc);
   portals[%(count)s] = portalEnt_%(count)s;'''

def addPortal(enumVal, ifcName):
    global portalCount
    portalList.append(portalTemplate % {'count': portalCount, 'enumVal': enumVal, 'ifcName': ifcName})
    portalCount = portalCount + 1

class iReq:
    def __init__(self):
        self.inst = ''
        self.args = []

memShareInst = '''   SharedMemoryPortalConfigInputPipes%(tparam)s l%(modname)sCW <- mkSharedMemoryPortalConfigInputPipes;'''

memEngineInst = '''   MemreadEngineV#(64,2,%(clientCount)s) lSharereadEngine <- mkMemreadEngine();
   MemwriteEngineV#(64,2,%(clientCount)s) lSharewriteEngine <- mkMemwriteEngine();'''

memModuleInstantiation = '''   SharedMemoryPortal#(64) l%(modname)sShare <- mkSharedMemory%(stype)sPortal(l%(modname)sPipes.portalIfc,
           lSharereadEngine.read_servers[%(clientCount)s], lSharewriteEngine.write_servers[%(clientCount)s]);'''

memConnection = '''   mkConnection(l%(modname)sCW, l%(modname)sShare.cfg);'''

connectUser = '''   mkConnection(lSimpleRequestInputPipes, %(args)s);'''

pipeInstantiation = '''   %(modname)sPipes%(tparam)s l%(modname)sPipes <- mk%(modname)sPipes;'''

connectInstantiation = '''   mkConnection(l%(modname)sPipes, l%(userIf)s);'''

def instMod(args, modname, modext, constructor, tparam, memFlag):
    global clientCount
    if not modname:
        return
    pmap['tparam'] = tparam
    pmap['modname'] = modname + modext
    tstr = 'S2H'
    if modext == 'Output':
        tstr = 'H2S'
    if modext:
        args = modname + tstr
    pmap['args'] = args % pmap
    if modext:
        enumList.append(modname + tstr)
        pmap['argsConfig'] = modname + memFlag + tstr
        if memFlag:
            if modext == 'Output':
                pmap['args'] = '';
                pmap['stype'] = 'Indication';
            else:
                pmap['args'] = 'l%(userIf)s' % pmap
                pmap['stype'] = 'Request';
            pmap['clientCount'] = clientCount;
            pipeInstantiate.append(pipeInstantiation % pmap)
            pipeInstantiate.append(memShareInst % pmap)
            portalInstantiate.append(memModuleInstantiation % pmap)
            connectInstantiate.append(memConnection % pmap)
            if modext != 'Output':
                connectInstantiate.append(connectUser % pmap)
            clientCount += 1
        elif modext == 'Output':
            pipeInstantiate.append(pipeInstantiation % pmap)
        else:
            pipeInstantiate.append(pipeInstantiation % pmap)
            connectInstantiate.append(connectInstantiation % pmap)
        if memFlag:
            enumList.append(modname + memFlag + tstr)
            addPortal(pmap['argsConfig'], '%(modname)sCW' % pmap)
        else:
            addPortal(pmap['args'], '%(modname)sPipes' % pmap)
    else:
        if not instantiateRequest.get(pmap['modname']):
            instantiateRequest[pmap['modname']] = iReq()
            instantiateRequest[pmap['modname']].inst = '   %(modname)s%(tparam)s l%(modname)s <- mk%(modname)s(%%s);' % pmap
        instantiateRequest[pmap['modname']].args.append(pmap['args'])
    if pmap['modname'] not in instantiatedModules:
        instantiatedModules.append(pmap['modname'])
    importfiles.append(modname)

def flushModules(key):
        temp = instantiateRequest.get(key)
        if temp:
            portalInstantiate.append(temp.inst % ','.join(temp.args))
            del instantiateRequest[key]

def parseParam(pitem, proxy):
    p = pitem.split(':')
    pmap = {'tparam': '', 'xparam': '', 'uparam': '', 'memFlag': 'Pipes' if p[0][0] == '/' else ''}
    pmap['usermod'] = p[0].replace('/','')
    pmap['name'] = p[1]
    ind = pmap['usermod'].find('#')
    if ind > 0:
        pmap['xparam'] = pmap['usermod'][ind:]
        pmap['usermod'] = pmap['usermod'][:ind]
    if len(p) > 2 and p[2]:
        pmap['uparam'] = p[2] + ', '
    return pmap

if __name__=='__main__':
    options = argparser.parse_args()

    if not options.project_dir:
        print "topgen: --project-dir option missing"
        sys.exit(1)
    project_dir = os.path.abspath(os.path.expanduser(options.project_dir))
    topFilename = project_dir + '/Top.bsv'
    print 'Writing Top:', topFilename
    clientCount = 0
    userFiles = []
    portalInstantiate = []
    pipeInstantiate = []
    connectInstantiate = []
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
        pmap = parseParam(pitem, True)
        ptemp = pmap['name']
        for pmap['name'] in ptemp.split(','):
            instMod('', pmap['name'], 'Output', '', '', pmap['memFlag'])
            argstr = pmap['uparam'] + 'l%(name)sOutputPipes.ifc'
            if pmap['uparam'] and pmap['uparam'][0] == '/':
                argstr = 'l%(name)sOutputPipes.ifc, ' + pmap['uparam'][1:-2]
            instMod(argstr, pmap['usermod'], '', '', pmap['xparam'], False)
            pmap['uparam'] = ''
    for pitem in options.wrapper:
        pmap = parseParam(pitem, False)
        pmap['userIf'] = pmap['name']
        pmap['name'] = pmap['usermod']
        pr = pmap['userIf'].split('.')
        pmap['usermod'] = pr[0]
        if pmap['usermod'] not in instantiatedModules:
            instMod(pmap['uparam'], pmap['usermod'], '', '', pmap['xparam'], False)
        flushModules(pmap['usermod'])
        instMod('', pmap['name'], 'Input', '', '', pmap['memFlag'])
        portalInstantiate.append('')
    for key in instantiatedModules:
        flushModules(key)
    for pitem in options.interface:
        p = pitem.split(':')
        interfaceList.append('   interface %s = l%s;' % (p[0], p[1]))

    memory_flag = 'MemServerCompat' in instantiatedModules
    if clientCount:
        pipeInstantiate.append(memEngineInst % {'clientCount': clientCount})
    topsubsts = {'enumList': ','.join(enumList),
                 'generatedImport': '\n'.join(['import %s::*;' % p for p in importfiles]),
                 'pipeInstantiate' : '\n'.join(sorted(pipeInstantiate)),
                 'connectInstantiate' : '\n'.join(sorted(connectInstantiate)),
                 'portalInstantiate' : '\n'.join(portalInstantiate),
                 'portalList': '\n'.join(portalList),
                 'portalCount': portalCount,
                 'exportedInterfaces' : '\n'.join(interfaceList),
                 'exportedNames' : '\n'.join(exportedNames),
                 'portalMaster' : 'lMemServerCompat.masters' if memory_flag else 'nil',
                 'moduleParam' : 'ConnectalTop#(PhysAddrWidth,DataBusWidth,`PinType,`NumberOfMasters)' 
#\ if memory_flag else 'StdConnectalTop#(PhysAddrWidth)'
                 }
    print 'TOPFN', topFilename
    top = util.createDirAndOpen(topFilename, 'w')
    top.write(topTemplate % topsubsts)
    top.close()
