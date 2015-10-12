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

def newArgparser():
    argparser = argparse.ArgumentParser("Generate Top.bsv for an project.")
    argparser.add_argument('--project-dir', help='project directory')
    argparser.add_argument('--interface', default=[], help='exported interface declaration', action='append')
    argparser.add_argument('--board', help='Board type')
    argparser.add_argument('--importfiles', default=[], help='added imports', action='append')
    argparser.add_argument('--portname', default=[], help='added portal names to enum list', action='append')
    argparser.add_argument('--wrapper', default=[], help='exported wrapper interfaces', action='append')
    argparser.add_argument('--proxy', default=[], help='exported proxy interfaces', action='append')
    argparser.add_argument('--memread', default=[], help='memory read interfaces', action='append')
    argparser.add_argument('--memwrite', default=[], help='memory read interfaces', action='append')
    argparser.add_argument('--cnoc', help='generate mkCnocTop', action='store_true')
    return argparser

argparser = newArgparser()

topTemplate='''
import Vector::*;
import Portal::*;
import CtrlMux::*;
import HostInterface::*;
import Connectable::*;
import MemReadEngine::*;
import MemWriteEngine::*;
import MemTypes::*;
import MemServer::*;
import IfcNames::*;
%(generatedImport)s

`ifndef IMPORT_HOSTIF
(* synthesize *)
`endif
module mkConnectalTop
`ifdef IMPORT_HOSTIF // no synthesis boundary
      #(HostInterface host)
`else
`ifdef IMPORT_HOST_CLOCKS // enables synthesis boundary
       #(Clock derivedClockIn, Reset derivedResetIn)
`else
// otherwise no params
`endif
`endif
       (%(moduleParam)s);
   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();
`ifdef IMPORT_HOST_CLOCKS // enables synthesis boundary
   HostInterface host = (interface HostInterface;
                           interface Clock derivedClock = derivedClockIn;
                           interface Reset derivedReset = derivedResetIn;
                         endinterface);
`endif
%(pipeInstantiate)s

%(portalInstantiate)s
%(connectInstantiate)s

   Vector#(%(portalCount)s,StdPortal) portals;
%(portalList)s
   let ctrl_mux <- mkSlaveMux(portals);
   Vector#(NumWriteClients,MemWriteClient#(DataBusWidth)) nullWriters = replicate(null_mem_write_client());
   Vector#(NumReadClients,MemReadClient#(DataBusWidth)) nullReaders = replicate(null_mem_read_client());
   interface interrupt = getInterruptVector(portals);
   interface slave = ctrl_mux;
   interface readers = take(%(portalReaders)s);
   interface writers = take(%(portalWriters)s);
%(pinsInterface)s
%(exportedInterfaces)s
endmodule : mkConnectalTop
%(exportedNames)s
'''

ifcnamesTemplate='''
typedef enum {NoInterface, %(enumList)s} IfcNames deriving (Eq,Bits);
'''

topNocTemplate='''
import Vector::*;
import Portal::*;
import CnocPortal::*;
import Connectable::*;
import HostInterface::*;
import IfcNames::*;
import MemTypes::*;
%(generatedImport)s

%(generatedTypedefs)s

`ifndef IMPORT_HOSTIF
(* synthesize *)
`endif
module mkCnocTop
`ifdef IMPORT_HOSTIF
       #(HostInterface host)
`else
`ifdef IMPORT_HOST_CLOCKS // enables synthesis boundary
       #(Clock derivedClockIn, Reset derivedResetIn)
`else
// otherwise no params
`endif
`endif
       (%(moduleParam)s);
   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();
`ifdef IMPORT_HOST_CLOCKS // enables synthesis boundary
   HostInterface host = (interface HostInterface;
                           interface Clock derivedClock = derivedClockIn;
                           interface Reset derivedReset = derivedResetIn;
                         endinterface);
`endif
%(pipeInstantiate)s

%(portalInstantiate)s
%(connectInstantiate)s

%(portalList)s
   Vector#(NumWriteClients,MemWriteClient#(DataBusWidth)) nullWriters = replicate(null_mem_write_client());
   Vector#(NumReadClients,MemReadClient#(DataBusWidth)) nullReaders = replicate(null_mem_read_client());

   interface requests = %(requestList)s;
   interface indications = %(indicationList)s;
   interface readers = take(%(portalReaders)s);
   interface writers = take(%(portalWriters)s);
%(exportedInterfaces)s
endmodule : mkCnocTop
%(exportedNames)s
'''

topEnumTemplate='''
typedef enum {NoInterface, %(enumList)s} IfcNames;
'''

portalTemplate = '''   PortalCtrlMemSlave#(SlaveControlAddrWidth,SlaveDataBusWidth) ctrlPort_%(count)s <- mkPortalCtrlMemSlave(extend(pack(%(enumVal)s)), l%(ifcName)s.portalIfc.intr);
   let memslave_%(count)s <- mkMemMethodMux%(slaveType)s(ctrlPort_%(count)s.memSlave,l%(ifcName)s.portalIfc.%(itype)s);
   portals[%(count)s] = (interface MemPortal;
       interface PhysMemSlave slave = memslave_%(count)s;
       interface ReadOnly interrupt = ctrlPort_%(count)s.interrupt;
       interface WriteOnly num_portals = ctrlPort_%(count)s.num_portals;
       endinterface);'''

portalNocTemplate = '''   let l%(ifcName)sNoc <- mkPortalMsg%(direction)s(extend(pack(%(enumVal)s)), l%(ifcName)s.portalIfc.%(itype)s%(messageSize)s);'''

def addPortal(enumVal, ifcName, direction):
    global portalCount
    portParam = {'count': portalCount, 'enumVal': enumVal, 'ifcName': ifcName, 'direction': direction}
    if direction == 'Request':
        requestList.append('l' + ifcName + 'Noc')
        portParam['itype'] = 'requests'
        portParam['slaveType'] = 'In'
        portParam['intrParam'] = ''
        portParam['messageSize'] = ''
    else:
        indicationList.append('l' + ifcName + 'Noc')
        portParam['itype'] = 'indications'
        portParam['slaveType'] = 'Out'
        portParam['intrParam'] = ', l%(ifcName)s.portalIfc.intr' % portParam
        portParam['messageSize'] = ', l%(ifcName)s.portalIfc.messageSize' % portParam
    p = portalNocTemplate if options.cnoc else portalTemplate
    portalList.append(p % portParam)
    portalCount = portalCount + 1

class iReq:
    def __init__(self):
        self.inst = ''
        self.args = []

memShareInst = '''   SharedMemoryPortalConfigInput%(tparam)s l%(modname)sCW <- mkSharedMemoryPortalConfigInput;'''

memEngineInst = '''   MemReadEngine#(64,64,2,%(clientCount)s) lSharereadEngine <- mkMemReadEngine();
   MemWriteEngine#(64,64,2,%(clientCount)s) lSharewriteEngine <- mkMemWriteEngine();'''

memModuleInstantiation = '''   SharedMemoryPortal#(64) l%(modname)sShare <- mkSharedMemory%(stype)sPortal(l%(modname)s%(number)s.portalIfc,
           get%(modnamebase)sMessageSize,
           takeAt(%(clientCount)s, lSharereadEngine.readServers), takeAt(%(clientCount)s, lSharewriteEngine.writeServers));'''

memConnection = '''   mkConnection(l%(modname)sCW.pipes, l%(modname)sShare.cfg);'''

connectUser = '''   mkConnection(lSimpleRequestInput.pipes, %(args)s);'''

connectIndication = '''   mkConnection(l%(usermod)s.inverseIfc, l%(modname)s.methods);'''

pipeInstantiation = '''   %(modname)s%(inverse)s%(tparam)s l%(modname)s%(number)s <- mk%(modname)s%(inverse)s;'''

connectInstantiation = '''   mkConnection(l%(modname)s%(number)s.pipes, l%(userIf)s);'''

def instMod(pmap, args, modname, modext, constructor, tparam, memFlag, inverseFlag):
    global clientCount
    if not modname:
        return
    map = pmap.copy()
    pmap['tparam'] = tparam
    pmap['modname'] = modname + modext
    pmap['modnamebase'] = modname
    tstr = 'S2H'
    if modext == 'Output':
        tstr = 'H2S'
    if modext:
        args = modname + tstr
    pmap['args'] = args % pmap
    if modext:
        options.portname.append('IfcNames_' + modname + tstr + pmap['number'])
        pmap['argsConfig'] = modname + memFlag + tstr
        if modext == 'Output':
            pmap['stype'] = 'Indication';
        else:
            pmap['stype'] = 'Request';
        if memFlag:
            if modext == 'Output':
                pmap['args'] = '';
            else:
                pmap['args'] = 'l%(userIf)s' % pmap
            pmap['clientCount'] = clientCount;
            pipeInstantiate.append(pipeInstantiation % pmap)
            pipeInstantiate.append(memShareInst % pmap)
            portalInstantiate.append(memModuleInstantiation % pmap)
            connectInstantiate.append(memConnection % pmap)
            if modext != 'Output':
                connectInstantiate.append(connectUser % pmap)
            clientCount += 2
        elif modext == 'Output':
            pipeInstantiate.append(pipeInstantiation % pmap)
            if inverseFlag:
                connectInstantiate.append(connectIndication % pmap)
        else:
            pipeInstantiate.append(pipeInstantiation % pmap)
            connectInstantiate.append(connectInstantiation % pmap)
        if memFlag:
            options.portname.append('IfcNames_' + modname + memFlag + tstr + pmap['number'])
            addPortal('IfcNames_' + pmap['argsConfig'], '%(modname)sCW' % pmap, 'Request')
        else:
            addPortal('IfcNames_' + pmap['args'] + pmap['number'], '%(modname)s%(number)s' % pmap, pmap['stype'])
    else:
        if not instantiateRequest.get(pmap['modname']):
            instantiateRequest[pmap['modname']] = iReq()
            if pmap['modname'] in ['MMU', 'MemServer']:
                pmap['hostif'] = ''
            else:
                pmap['hostif'] = ''
# If needed, can't these be passed in as extra args on H2S or S2H spec line? jca 2015/7/22
#                pmap['hostif'] = ('\n'
#                                  '`ifdef IMPORT_HOSTIF\n'
#                                  '                    host,\n'
#                                  '`else\n'
#                                  '`ifdef IMPORT_HOST_CLOCKS\n'
#                                  '                    host.derivedClock, host.derivedReset,\n'
#                                  '`endif\n'
#                                  '`endif\n'
#                                  '                    ')
            instantiateRequest[pmap['modname']].inst = '   %(modname)s%(tparam)s l%(modname)s <- mk%(modname)s(%(hostif)s%%s);' % pmap
        instantiateRequest[pmap['modname']].args.append(pmap['args'])
    if pmap['modname'] not in instantiatedModules:
        instantiatedModules.append(pmap['modname'])
    options.importfiles.append(modname)

def flushModules(key):
        temp = instantiateRequest.get(key)
        if temp:
            portalInstantiate.append(temp.inst % ','.join(temp.args))
            del instantiateRequest[key]

def toVectorLiteral(l):
    if l:
        return 'cons(%s,%s)' % (l[0], toVectorLiteral(l[1:]))
    else:
        return 'nil'

def parseParam(pitem, proxy):
    p = pitem.split(':')
    pmap = {'tparam': '', 'xparam': '', 'uparam': '', 'memFlag': 'Pipes' if p[0][0] == '/' else '', 'inverse': 'Pipes' if p[0][0] == '!' else ''}
    pmap['usermod'] = p[0].replace('/','').replace('!','')
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
    clientCount = 0
    userFiles = []
    portalInstantiate = []
    pipeInstantiate = []
    connectInstantiate = []
    instantiateRequest = {}
    for item in ['IfcNames_MemServerRequestS2H', 'IfcNames_MMURequestS2H', 'IfcNames_MemServerIndicationH2S', 'IfcNames_MMUIndicationH2S']:
        options.portname.append(item)
    requestList = []
    indicationList = []
    portalList = []
    portalCount = 0
    instantiatedModules = []
    exportedNames = []
    options.importfiles.append('`PinTypeInclude')
    if options.board == 'xsim':
        options.cnoc = True
    if options.cnoc:
        exportedNames.extend(['export mkCnocTop;', 'export NumberOfRequests;', 'export NumberOfIndications;'])
    else:
        exportedNames.extend(['export mkConnectalTop;'])
    if options.importfiles:
        for item in options.importfiles:
             exportedNames.append('export %s::*;' % item)
    interfaceList = []

    modcount = {}
    for pitem in options.proxy:
        print 'options.proxy: %s' % options.proxy
        pmap = parseParam(pitem, True)
        ptemp = pmap['name'].split(',')
        for pmap['name'] in ptemp:
            pmap['number'] = ''
            if (ptemp.count(pmap['name']) > 1):
                if pmap['name'] in modcount:
                    pmap['number'] = str(modcount[pmap['name']])
                    modcount[pmap['name']] += 1
                else:
                    modcount[pmap['name']] = 1
                    pmap['number'] = str(0)
            instMod(pmap, '', pmap['name'], 'Output', '', '', pmap['memFlag'], pmap['inverse'])
            argstr = pmap['uparam'] + ('l%(name)sOutput%(number)s.ifc' if not pmap['inverse'] else '')
            if pmap['uparam'] and pmap['uparam'][0] == '/':
                argstr = 'l%(name)sOutput%(number)s.ifc, ' + pmap['uparam'][1:-2]
            instMod(pmap, argstr, pmap['usermod'], '', '', pmap['xparam'], False, pmap['inverse'])
            pmap['uparam'] = ''
    modcount = {}
    for pitem in options.wrapper:
        pmap = parseParam(pitem, False)
        print 'options.wrapper: %s %s' % (pitem, pmap)
        pmap['userIf'] = pmap['name']
        pmap['name'] = pmap['usermod']
        pmap['number'] = ''
        pr = pmap['userIf'].split('.')
        pmap['usermod'] = pr[0]
        modintf_list = pr[1].split(',')
        numbers = range(0,len(modintf_list)) if len(modintf_list) > 1 else ['']
        for (modintf,number) in zip(modintf_list, numbers):
            pmap['number'] = str(number)
            pmap['userIf'] = '%s.%s' % (pmap['usermod'], modintf)
            if pmap['usermod'] not in instantiatedModules:
                instMod(pmap, pmap['uparam'], pmap['usermod'], '', '', pmap['xparam'], False, False)
            flushModules(pmap['usermod'])
            instMod(pmap, '', pmap['name'], 'Input', '', '', pmap['memFlag'], pmap['inverse'])
            portalInstantiate.append('')
    for key in instantiatedModules:
        flushModules(key)
    for pitem in options.interface:
        p = pitem.split(':')
        interfaceList.append('   interface %s = l%s;' % (p[0], p[1]))

    memory_flag = 'MemServer' in instantiatedModules
    if clientCount:
        pipeInstantiate.append(memEngineInst % {'clientCount': clientCount})
    topsubsts = {'enumList': ','.join(options.portname),
                 'generatedImport': '\n'.join(['import %s::*;' % p for p in options.importfiles]),
                 'generatedTypedefs': '\n'.join(['typedef %d NumberOfRequests;' % len(requestList),
                                                 'typedef %d NumberOfIndications;' % len(indicationList)]),
                 'pipeInstantiate' : '\n'.join(sorted(pipeInstantiate)),
                 'connectInstantiate' : '\n'.join(sorted(connectInstantiate)),
                 'portalInstantiate' : '\n'.join(portalInstantiate),
                 'portalList': '\n'.join(portalList),
                 'portalCount': portalCount,
                 'requestList': toVectorLiteral(requestList),
                 'indicationList': toVectorLiteral(indicationList),
                 'exportedInterfaces' : '\n'.join(interfaceList),
                 'exportedNames' : '\n'.join(exportedNames),
                 'portalReaders' : ('append(' if len(options.memread) > 0 else '(') + ', '.join(options.memread + ['nullReaders']) + ')',
                 'portalWriters' : ('append(' if len(options.memwrite) > 0 else '(') + ', '.join(options.memwrite + ['nullWriters']) + ')',
                 'portalMaster' : 'lMemServer.masters' if memory_flag else 'nil',
#TODO: add a flag to enable pins interface                 
                 'pinsInterface' : '    interface pins = l%(usermod)s.pins;\n' % pmap if False else '',
                 'moduleParam' : 'ConnectalTop' if not options.cnoc \
                     else 'CnocTop#(NumberOfRequests,NumberOfIndications,PhysAddrWidth,DataBusWidth,`PinType,NumberOfMasters)'
                 }
    topFilename = project_dir + '/Top.bsv'
    print 'Writing:', topFilename
    top = util.createDirAndOpen(topFilename, 'w')
    if options.cnoc:
        top.write(topNocTemplate % topsubsts)
    else:
        top.write(topTemplate % topsubsts)
    top.close()
    topFilename = project_dir + '/IfcNames.bsv'
    print 'Writing:', topFilename
    top = util.createDirAndOpen(topFilename, 'w')
    top.write(ifcnamesTemplate % topsubsts)
    top.close()
    topFilename = project_dir + '/../jni/topEnum.h'
    print 'Writing:', topFilename
    top = util.createDirAndOpen(topFilename, 'w')
    top.write(topEnumTemplate % topsubsts)
    top.close()
