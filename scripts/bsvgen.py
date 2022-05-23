##
## Copyright (C) 2012-2013 Nokia, Inc
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

##
from __future__ import print_function

import os
import math
import re
import hashlib

import AST
import string
import util

try:
    xrange
except NameError:
    xrange = range  # Python 3 compatibility

preambleTemplate='''
import FIFO::*;
import FIFOF::*;
import GetPut::*;
import Connectable::*;
import Clocks::*;
import FloatingPoint::*;
import Adapter::*;
import Leds::*;
import Vector::*;
import SpecialFIFOs::*;
import ConnectalConfig::*;
import ConnectalMemory::*;
import Portal::*;
import CtrlMux::*;
import ConnectalMemTypes::*;
import Pipe::*;
import HostInterface::*;
import LinkerLib::*;
%(extraImports)s

'''

requestStructTemplate='''
typedef struct {
%(paramStructDeclarations)s
} %(MethodName)s_Message deriving (Bits);
'''

requestOutputPipeInterfaceTemplate='''\
    interface PipeOut#(%(MethodName)s_Message) %(methodName)s_PipeOut;
'''

exposedProxyInterfaceTemplate='''
// exposed proxy interface
typedef PipePortal#(0, %(channelCount)s, SlaveDataBusWidth) %(Ifc)sPortalOutput;
interface %(Ifc)sOutput;
    interface %(Ifc)sPortalOutput portalIfc;
    interface %(Package)s%(Ifc)s ifc;
endinterface
interface %(Dut)s;
    interface StdPortal portalIfc;
    interface %(Package)s%(Ifc)s ifc;
endinterface

interface %(Ifc)sOutputPipeMethods;
%(indicationMethodDecls)s
endinterface

interface %(Ifc)sOutputPipes;
    interface %(Ifc)sOutputPipeMethods methods;
    interface %(Ifc)sPortalOutput portalIfc;
endinterface

function Bit#(16) get%(Ifc)sMessageSize(Bit#(16) methodNumber);
    case (methodNumber)%(messageSizes)s
    endcase
endfunction

(* synthesize *)
module mk%(Ifc)sOutputPipes(%(Ifc)sOutputPipes);
    Vector#(%(channelCount)s, PipeOut#(Bit#(SlaveDataBusWidth))) indicationPipes;
%(indicationMethodRules)s
    PortalInterrupt#(SlaveDataBusWidth) intrInst <- mkPortalInterrupt(indicationPipes);
    interface %(Ifc)sOutputPipeMethods methods;
%(indicationMethodAssigns)s
    endinterface
    interface PipePortal portalIfc;
        interface PortalSize messageSize;
            method size = get%(Ifc)sMessageSize;
        endinterface
        interface Vector requests = nil;
        interface Vector indications = indicationPipes;
        interface PortalInterrupt intr = intrInst;
    endinterface
endmodule

(* synthesize *)
module mk%(Ifc)sOutput(%(Ifc)sOutput);
    let indicationPipes <- mk%(Ifc)sOutputPipes;
    interface %(Package)s%(Ifc)s ifc;
%(indicationMethods)s
    endinterface
    interface PipePortal portalIfc = indicationPipes.portalIfc;
endmodule
instance PortalMessageSize#(%(Ifc)sOutput);
   function Bit#(16) portalMessageSize(%(Ifc)sOutput p, Bit#(16) methodNumber);
      return get%(Ifc)sMessageSize(methodNumber);
   endfunction
endinstance


interface %(Ifc)sInverse;
%(indicationInverseMethodDecls)s
endinterface

interface %(Ifc)sInverter;
    interface %(Package)s%(Ifc)s ifc;
    interface %(Ifc)sInverse inverseIfc;
endinterface

instance Connectable#(%(Ifc)sInverse, %(Ifc)sOutputPipeMethods);
   module mkConnection#(%(Ifc)sInverse in, %(Ifc)sOutputPipeMethods out)(Empty);
%(indicationInverseConnect)s
   endmodule
endinstance

(* synthesize *)
module mk%(Ifc)sInverter(%(Ifc)sInverter);
%(inverseIndicationMethodRules)s
    interface %(Package)s%(Ifc)s ifc;
%(inverseIndicationMethods)s
    endinterface
    interface %(Ifc)sInverse inverseIfc;
%(inverseIndicationInverseMethods)s
    endinterface
endmodule

(* synthesize *)
module mk%(Ifc)sInverterV(%(Ifc)sInverter);
%(wInverseIndicationMethodRules)s
    interface %(Package)s%(Ifc)s ifc;
%(wInverseIndicationMethods)s
    endinterface
    interface %(Ifc)sInverse inverseIfc;
%(wInverseIndicationInverseMethods)s
    endinterface
endmodule

// synthesizeable proxy MemPortal
(* synthesize *)
module mk%(Dut)sSynth#(Bit#(SlaveDataBusWidth) id)(%(Dut)s);
  let dut <- mk%(Ifc)sOutput();
  PortalCtrlMemSlave#(SlaveControlAddrWidth,SlaveDataBusWidth) ctrlPort <- mkPortalCtrlMemSlave(id, dut.portalIfc.intr);
  let memslave  <- mkMemMethodMuxOut(ctrlPort.memSlave,dut.portalIfc.indications);
  interface MemPortal portalIfc = (interface MemPortal;
      interface PhysMemSlave slave = memslave;
      interface ReadOnly interrupt = ctrlPort.interrupt;
      interface WriteOnly num_portals = ctrlPort.num_portals;
    endinterface);
  interface %(Package)s%(Ifc)s ifc = dut.ifc;
endmodule

// exposed proxy MemPortal
module mk%(Dut)s#(idType id)(%(Dut)s)
   provisos (Bits#(idType, a__),
	     Add#(b__, a__, SlaveDataBusWidth));
   let rv <- mk%(Dut)sSynth(extend(pack(id)));
   return rv;
endmodule
'''

exposedWrapperInterfaceTemplate='''
%(requestElements)s
// exposed wrapper portal interface
interface %(Ifc)sInputPipes;
%(requestOutputPipeInterfaces)s
endinterface
typedef PipePortal#(%(channelCount)s, 0, SlaveDataBusWidth) %(Ifc)sPortalInput;
interface %(Ifc)sInput;
    interface %(Ifc)sPortalInput portalIfc;
    interface %(Ifc)sInputPipes pipes;
endinterface
interface %(Dut)sPortal;
    interface %(Ifc)sPortalInput portalIfc;
endinterface
// exposed wrapper MemPortal interface
interface %(Dut)s;
    interface StdPortal portalIfc;
endinterface

instance Connectable#(%(Ifc)sInputPipes,%(Ifc)s);
   module mkConnection#(%(Ifc)sInputPipes pipes, %(Ifc)s ifc)(Empty);
%(mkConnectionMethodRules)s
   endmodule
endinstance

// exposed wrapper Portal implementation
(* synthesize *)
module mk%(Ifc)sInput(%(Ifc)sInput);
    Vector#(%(channelCount)s, PipeIn#(Bit#(SlaveDataBusWidth))) requestPipeIn;
%(methodRules)s
    interface PipePortal portalIfc;
        interface PortalSize messageSize;
        method Bit#(16) size(Bit#(16) methodNumber);
            case (methodNumber)%(messageSizes)s
            endcase
        endmethod
        endinterface
        interface Vector requests = requestPipeIn;
        interface Vector indications = nil;
        interface PortalInterrupt intr;
           method Bool status();
              return False;
           endmethod
           method Bit#(dataWidth) channel();
              return -1;
           endmethod
        endinterface
    endinterface
    interface %(Ifc)sInputPipes pipes;
%(outputPipes)s
    endinterface
endmodule

module mk%(Dut)sPortal#(%(Ifc)s ifc)(%(Dut)sPortal);
    let dut <- mk%(Ifc)sInput;
    mkConnection(dut.pipes, ifc);
    interface PipePortal portalIfc = dut.portalIfc;
endmodule

interface %(Dut)sMemPortalPipes;
    interface %(Ifc)sInputPipes pipes;
    interface MemPortal#(12,32) portalIfc;
endinterface

(* synthesize *)
module mk%(Dut)sMemPortalPipes#(Bit#(SlaveDataBusWidth) id)(%(Dut)sMemPortalPipes);

  let dut <- mk%(Ifc)sInput;
  PortalCtrlMemSlave#(SlaveControlAddrWidth,SlaveDataBusWidth) ctrlPort <- mkPortalCtrlMemSlave(id, dut.portalIfc.intr);
  let memslave  <- mkMemMethodMuxIn(ctrlPort.memSlave,dut.portalIfc.requests);
  interface %(Ifc)sInputPipes pipes = dut.pipes;
  interface MemPortal portalIfc = (interface MemPortal;
      interface PhysMemSlave slave = memslave;
      interface ReadOnly interrupt = ctrlPort.interrupt;
      interface WriteOnly num_portals = ctrlPort.num_portals;
    endinterface);
endmodule

// exposed wrapper MemPortal implementation
module mk%(Dut)s#(idType id, %(Ifc)s ifc)(%(Dut)s)
   provisos (Bits#(idType, a__),
	     Add#(b__, a__, SlaveDataBusWidth));
  let dut <- mk%(Dut)sMemPortalPipes(zeroExtend(pack(id)));
  mkConnection(dut.pipes, ifc);
  interface MemPortal portalIfc = dut.portalIfc;
endmodule
'''

requestRuleTemplate='''
    AdapterFromBus#(SlaveDataBusWidth,%(MethodName)s_Message) %(methodName)s_requestAdapter <- mkAdapterFromBus();
    requestPipeIn[%(channelNumber)s] = %(methodName)s_requestAdapter.in;
'''

methodDefTemplate='''
    method Action %(methodName)s(%(formals)s);'''

interfaceDefTemplate = '''
interface %(Ifc)s;%(methodDef)s
endinterface
'''

messageSizeTemplate='''
            %(channelNumber)s: return fromInteger(valueOf(SizeOf#(%(MethodName)s_Message)));'''

mkConnectionMethodTemplate='''
    rule handle_%(methodName)s_request;
        let request <- toGet(pipes.%(methodName)s_PipeOut).get();
        ifc.%(methodName)s(%(paramsForCall)s);
    endrule
'''

indicationRuleTemplate='''
    AdapterToBus#(SlaveDataBusWidth,%(MethodName)s_Message) %(methodName)s_responseAdapter <- mkAdapterToBus();
    indicationPipes[%(channelNumber)s] = %(methodName)s_responseAdapter.out;
'''

indicationDeclTemplate='''    interface PipeIn#(%(MethodName)s_Message) %(methodName)s;
'''

indicationAssignTemplate='''    interface %(methodName)s = %(methodName)s_responseAdapter.in;
'''

indicationMethodTemplate='''
    method Action %(methodName)s(%(formals)s);
        indicationPipes.methods.%(methodName)s.enq(%(MethodName)s_Message {%(structElements)s});
        //$display(\"indicationMethod \'%(methodName)s\' invoked\");
    endmethod'''

indicationInverseDeclTemplate='''    method ActionValue#(%(MethodName)s_Message) %(methodName)s;
'''

inverseIndicationRuleTemplate='''    FIFOF#(%(MethodName)s_Message) fifo_%(methodName)s <- mkFIFOF();
'''

inverseIndicationMethodTemplate='''
    method Action %(methodName)s(%(formals)s);
        fifo_%(methodName)s.enq(%(MethodName)s_Message {%(structElements)s});
    endmethod'''

inverseIndicationInverseMethodTemplate='''
    method ActionValue#(%(MethodName)s_Message) %(methodName)s;
        fifo_%(methodName)s.deq;
        return fifo_%(methodName)s.first;
    endmethod'''

indicationInverseConnectTemplate='''    mkConnection(in.%(methodName)s, out.%(methodName)s);
'''

wInverseIndicationRuleTemplate='''    PutInverter#(%(MethodName)s_Message) inv_%(methodName)s <- mkPutInverter();
'''

wInverseIndicationMethodTemplate='''
    method Action %(methodName)s(%(formals)s);
        inv_%(methodName)s.mod.put(%(MethodName)s_Message {%(structElements)s});
    endmethod'''

wInverseIndicationInverseMethodTemplate='''
    method ActionValue#(%(MethodName)s_Message) %(methodName)s;
        let v <- inv_%(methodName)s.inverse.get;
        return v;
    endmethod'''

def toBsvType(titem, oitem):
    if oitem and oitem['name'].startswith('Tuple'):
        titem = oitem
    if titem.get('params') and len(titem['params']):
        return '%s#(%s)' % (titem['name'], ','.join([str(toBsvType(p, None)) for p in titem['params']]))
    elif titem['name'] == 'fixed32':
        return 'Bit#(32)'
    else:
        return titem['name']

def collectElements(mlist, workerfn, name):
    methods = []
    mindex = 0
    for item in mlist:
        if verbose:
            print('collectEl', item)
            for p in item['dparams']:
                print('collectEl/param', p)
                break
        sub = { 'dut': util.decapitalize(name),
          'Dut': util.capitalize(name),
          'methodName': item['dname'],
          'MethodName': util.capitalize(item['dname']),
          'channelNumber': mindex}
        paramStructDeclarations = ['    %s %s;' % (toBsvType(p['ptype'], p.get('oldtype')), p['pname']) for p in item['dparams']]
        sub['paramType'] = ', '.join(['%s' % toBsvType(p['ptype'], p.get('oldtype')) for p in item['dparams']])
        sub['formals'] = ', '.join(['%s %s' % (toBsvType(p['ptype'], p.get('oldtype')), p['pname']) for p in item['dparams']])
        structElements = ['%s: %s' % (p['pname'], p['pname']) for p in item['dparams']]
        if not item['dparams']:
            paramStructDeclarations = ['    %s %s;' % ('Bit#(32)', 'padding')]
            structElements = ['padding: 0']
        sub['paramStructDeclarations'] = '\n'.join(paramStructDeclarations)
        sub['structElements'] = ', '.join(structElements)
        methods.append(workerfn % sub)
        mindex = mindex + 1
    return ''.join(methods)

def fixupSubsts(item, suffix):
    name = item['cname']+suffix
    dlist = item['cdecls']
    mkConnectionMethodRules = []
    outputPipes = []
    for m in dlist:
        if verbose:
            print('fixupSubsts', m)
        paramsForCall = ['request.%s' % p['pname'] for p in m['dparams']]
        msubs = {'methodName': m['dname'],
                 'paramsForCall': ', '.join(paramsForCall)}
        mkConnectionMethodRules.append(mkConnectionMethodTemplate % msubs)
        outputPipes.append('        interface %(methodName)s_PipeOut = %(methodName)s_requestAdapter.out;' % msubs)
    substs = {
        'Package': '',
        'channelCount': len(dlist),
        'Ifc': item['cname'],
        'dut': util.decapitalize(name),
        'Dut': util.capitalize(name),
    }
    if not generateInterfaceDefs:
        substs['Package'] = item['Package'] + '::'
    substs['requestOutputPipeInterfaces'] = ''.join(
        [requestOutputPipeInterfaceTemplate % {'methodName': m['dname'],
                                               'MethodName': util.capitalize(m['dname'])} for m in dlist])
    substs['outputPipes'] = '\n'.join(outputPipes)
    substs['mkConnectionMethodRules'] = ''.join(mkConnectionMethodRules)
    substs['indicationMethodRules'] = collectElements(dlist, indicationRuleTemplate, name)
    substs['indicationMethodDecls'] = collectElements(dlist, indicationDeclTemplate, name)
    substs['indicationMethodAssigns'] = collectElements(dlist, indicationAssignTemplate, name)
    substs['indicationMethods'] = collectElements(dlist, indicationMethodTemplate, name)
    substs['indicationInverseMethodDecls'] = collectElements(dlist, indicationInverseDeclTemplate, name)
    substs['inverseIndicationMethodRules'] = collectElements(dlist, inverseIndicationRuleTemplate, name)
    substs['inverseIndicationMethods'] = collectElements(dlist, inverseIndicationMethodTemplate, name)
    substs['inverseIndicationInverseMethods'] = collectElements(dlist, inverseIndicationInverseMethodTemplate, name)
    substs['indicationInverseConnect'] = collectElements(dlist, indicationInverseConnectTemplate, name)
    substs['wInverseIndicationMethodRules'] = collectElements(dlist, wInverseIndicationRuleTemplate, name)
    substs['wInverseIndicationMethods'] = collectElements(dlist, wInverseIndicationMethodTemplate, name)
    substs['wInverseIndicationInverseMethods'] = collectElements(dlist, wInverseIndicationInverseMethodTemplate, name)
    substs['requestElements'] = collectElements(dlist, requestStructTemplate, name)
    substs['methodRules'] = collectElements(dlist, requestRuleTemplate, name)
    substs['methodDef'] = collectElements(dlist, methodDefTemplate, name)
    substs['messageSizes'] = collectElements(dlist, messageSizeTemplate, name)
    return substs

def indent(f, indentation):
    for i in xrange(indentation):
        f.write(' ')

def bemitStructMember(item, f, indentation):
    if verbose:
        print('emitSM', item)
    indent(f, indentation)
    f.write('%s %s' % (toBsvType(item['ptype'], item.get('oldtype')), item['pname']))
    #if hasBitWidth(item['ptype']):
    #    f.write(' : %d' % typeBitWidth(item['ptype']))
    f.write(';\n')

def bemitStruct(item, name, f, indentation):
    indent(f, indentation)
    if (indentation == 0):
        f.write('typedef ')
    f.write('struct {\n')
    for e in item['elements']:
        bemitStructMember(e, f, indentation+4)
    indent(f, indentation)
    f.write('}')
    if (indentation == 0):
        f.write(' %s deriving (Bits);' % name)
    f.write('\n')

def bemitType(item, name, f, indentation):
    indent(f, indentation)
    tmp = toBsvType(item, None)
    if re.match('[0-9]+', tmp):
        if True or verbose:
            print('bsvgen/bemitType: INFO ignore numeric typedef for', tmp)
        return
    if not tmp or tmp[0] == '`' or tmp == 'Empty' or tmp[-2:] == '_P':
        if True or verbose:
            print('bsvgen/bemitType: INFO ignore typedef for', tmp)
        return
    if (indentation == 0):
        f.write('typedef ')
    f.write(tmp)
    if (indentation == 0):
        f.write(' %s deriving (Bits);' % name)
    f.write('\n')

def bemitEnum(item, name, f, indentation):
    indent(f, indentation)
    if (indentation == 0):
        f.write('typedef ')
    f.write('enum %s { ' % name)
    indent(f, indentation)
    f.write(', '.join(['%s_%s' % (name, e) for e in item['elements']]))
    indent(f, indentation)
    f.write(' }')
    if (indentation == 0):
        f.write(' %s deriving (Bits);' % name)
    f.write('\n')

def emitBDef(item, generated_hpp, indentation):
    if verbose:
        print('bsvgen/emitBDef:', item)
    n = item['tname']
    td = item['tdtype']
    t = td.get('type')
    if t == 'Enum':
        bemitEnum(td, n, generated_hpp, indentation)
    elif t == 'Struct':
        bemitStruct(td, n, generated_hpp, indentation)
    elif t == 'Type' or t == None:
        bemitType(td, n, generated_hpp, indentation)
    else:
        print('EMITCD', n, t, td)

def generate_bsv(project_dir, noisyFlag, aGenDef, jsondata):
    global generateInterfaceDefs,verbose
    verbose = noisyFlag
    generateInterfaceDefs = aGenDef
    generatedPackageNames = []
    if generateInterfaceDefs:
        fname = os.path.join(project_dir, 'generatedbsv', 'GeneratedTypes.bsv')
        if_file = util.createDirAndOpen(fname, 'w')
        for v in jsondata['globaldecls']:
            if v['dtype'] == 'TypeDef':
                if v.get('tparams'):
                    print('Skipping BSV declaration for parameterized type', v['tname'])
                    continue
                emitBDef(v, if_file, 0)
        if_file.write('\n')
    for item in jsondata['interfaces']:
        if verbose:
            print('genbsv', item)
        pname = item['cname']
        if pname in generatedPackageNames:
            continue
        generatedPackageNames.append(pname)
        fname = os.path.join(project_dir, 'generatedbsv', '%s.bsv' % pname)
        bsv_file = util.createDirAndOpen(fname, 'w')
        bsv_file.write('package %s;\n' % pname)
        if generateInterfaceDefs:
            extraImports = ['HostInterface', 'GeneratedTypes']
        else:
            extraImports = [item['Package']]
            extraImports += [i for i in jsondata['globalimports'] if not i in generatedPackageNames]
        bsv_file.write(preambleTemplate % {'extraImports' : ''.join(['import %s::*;\n' % pn for pn in extraImports])})
        if verbose:
            print('Writing file ', fname)
        if generateInterfaceDefs:
            if_file.write(interfaceDefTemplate % fixupSubsts(item, ''))
        
        bsv_file.write(exposedWrapperInterfaceTemplate % fixupSubsts(item, 'Wrapper'))
        bsv_file.write(exposedProxyInterfaceTemplate % fixupSubsts(item, 'Proxy'))
        bsv_file.write('endpackage: %s\n' % pname)
        bsv_file.close()
    if generateInterfaceDefs:
        if_file.close()

