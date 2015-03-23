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
import os
import math
import re
import md5

import globalv
import AST
import string
import util

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
import ConnectalMemory::*;
import Portal::*;
import MemPortal::*;
import MemTypes::*;
import Pipe::*;
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
interface %(Ifc)sOutputPipes;
    interface PipePortal#(0, %(channelCount)s, 32) portalIfc;
    interface %(Package)s::%(Ifc)s ifc;
endinterface
interface %(Dut)s;
    interface StdPortal portalIfc;
    interface %(Package)s::%(Ifc)s ifc;
endinterface

(* synthesize *)
module %(moduleContext)s mk%(Ifc)sOutputPipes(%(Ifc)sOutputPipes);
    Vector#(%(channelCount)s, PipeOut#(Bit#(32))) indicationPipes = newVector();
%(indicationMethodRules)s
    PortalInterrupt#(32) intrInst <- mkPortalInterrupt(indicationPipes);
    interface %(Package)s::%(Ifc)s ifc;
%(indicationMethods)s
    endinterface
    interface PipePortal portalIfc;
        method Bit#(16) messageSize(Bit#(16) methodNumber);
            case (methodNumber)%(messageSizes)s
            endcase
        endmethod
        interface Vector requests = nil;
        interface Vector indications = indicationPipes;
        interface PortalInterrupt intr = intrInst;
    endinterface
endmodule

// synthesizeable proxy MemPortal
(* synthesize *)
module mk%(Dut)sSynth#(Bit#(32) id)(%(Dut)s);
  let dut <- mk%(Ifc)sOutputPipes();
  let memPortal <- mkMemPortal(id, dut.portalIfc);
  interface MemPortal portalIfc = memPortal;
  interface %(Package)s::%(Ifc)s ifc = dut.ifc;
endmodule

// exposed proxy MemPortal
module mk%(Dut)s#(idType id)(%(Dut)s)
   provisos (Bits#(idType, a__),
	     Add#(b__, a__, 32));
   let rv <- mk%(Dut)sSynth(extend(pack(id)));
   return rv;
endmodule
'''

exposedWrapperInterfaceTemplate='''
%(requestElements)s
// exposed wrapper portal interface
interface %(Ifc)sInputPipes;
    interface PipePortal#(%(channelCount)s, 0, 32) portalIfc;
%(requestOutputPipeInterfaces)s
endinterface
interface %(Dut)sPortal;
    interface PipePortal#(%(channelCount)s, 0, 32) portalIfc;
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
module mk%(Ifc)sInputPipes(%(Ifc)sInputPipes);
    Vector#(%(channelCount)s, PipeIn#(Bit#(32))) requestPipeIn = newVector();
%(methodRules)s
    interface PipePortal portalIfc;
        method Bit#(16) messageSize(Bit#(16) methodNumber);
            case (methodNumber)%(messageSizes)s
            endcase
        endmethod
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
%(outputPipes)s
endmodule

module mk%(Dut)sPortal#(%(Ifc)s ifc)(%(Dut)sPortal);
    let pipes <- mk%(Ifc)sInputPipes;
    mkConnection(pipes, ifc);
    interface PipePortal portalIfc = pipes.portalIfc;
endmodule

interface %(Dut)sMemPortalPipes;
    interface %(Ifc)sInputPipes pipes;
    interface StdPortal portalIfc;
endinterface

(* synthesize *)
module mk%(Dut)sMemPortalPipes#(Bit#(32) id)(%(Dut)sMemPortalPipes);

  let p <- mk%(Ifc)sInputPipes;
  let memPortal <- mkMemPortal(id, p.portalIfc);
  interface %(Ifc)sInputPipes pipes = p;
  interface MemPortal portalIfc = memPortal;
endmodule

// exposed wrapper MemPortal implementation
module mk%(Dut)s#(idType id, %(Ifc)s ifc)(%(Dut)s)
   provisos (Bits#(idType, a__),
	     Add#(b__, a__, 32));
  let dut <- mk%(Dut)sMemPortalPipes(zeroExtend(pack(id)));
  mkConnection(dut.pipes, ifc);
  interface MemPortal portalIfc = dut.portalIfc;
endmodule
'''

requestRuleTemplate='''
    AdapterFromBus#(32,%(MethodName)s_Message) %(methodName)s_requestFifo <- mkAdapterFromBus();
    requestPipeIn[%(channelNumber)s] = %(methodName)s_requestFifo.in;
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
    AdapterToBus#(32,%(MethodName)s_Message) %(methodName)s_responseFifo <- mkAdapterToBus();
    indicationPipes[%(channelNumber)s] = %(methodName)s_responseFifo.out;
'''

indicationMethodDeclTemplate='''
    method Action %(methodName)s(%(formals)s);'''

indicationMethodTemplate='''
    method Action %(methodName)s(%(formals)s);
        %(methodName)s_responseFifo.in.enq(%(MethodName)s_Message {%(structElements)s});
        //$display(\"indicationMethod \'%(methodName)s\' invoked\");
    endmethod'''

def toBsvType(titem):
    if len(titem['params']):
        return '%s#(%s)' % (titem['name'], ','.join([str(toBsvType(p)) for p in titem['params']]))
    else:
        return titem['name']

def collectElements(mlist, workerfn, name):
    methods = []
    mindex = 0
    for item in mlist:
        sub = { 'dut': util.decapitalize(name),
          'Dut': util.capitalize(name),
          'methodName': item['name'],
          'MethodName': util.capitalize(item['name']),
          'channelNumber': mindex}
        paramStructDeclarations = ['    %s %s;' % (toBsvType(p['type']), p['name']) for p in item['params']]
        sub['paramType'] = ', '.join(['%s' % toBsvType(p['type']) for p in item['params']])
        sub['formals'] = ', '.join(['%s %s' % (toBsvType(p['type']), p['name']) for p in item['params']])
        structElements = ['%s: %s' % (p['name'], p['name']) for p in item['params']]
        if not item['params']:
            paramStructDeclarations = ['    %s %s;' % ('Bit#(32)', 'padding')]
            structElements = ['padding: 0']
        sub['paramStructDeclarations'] = '\n'.join(paramStructDeclarations)
        sub['structElements'] = ', '.join(structElements)
        methods.append(workerfn % sub)
        mindex = mindex + 1
    return ''.join(methods)

def fixupSubsts(item, suffix):
    name = item['name']+suffix
    dlist = item['decls']
    mkConnectionMethodRules = []
    outputPipes = []
    for m in dlist:
        paramsForCall = ['request.%s' % p['name'] for p in m['params']]
        msubs = {'methodName': m['name'],
                 'paramsForCall': ', '.join(paramsForCall)}
        mkConnectionMethodRules.append(mkConnectionMethodTemplate % msubs)
        outputPipes.append('    interface %(methodName)s_PipeOut = %(methodName)s_requestFifo.out;' % msubs)
    substs = {
        'Package': item['Package'],
        'channelCount': len(dlist),
        'moduleContext': item['moduleContext'],
        'Ifc': item['name'],
        'dut': util.decapitalize(name),
        'Dut': util.capitalize(name),
    }
    substs['requestOutputPipeInterfaces'] = ''.join(
        [requestOutputPipeInterfaceTemplate % {'methodName': p['name'],
                                               'MethodName': util.capitalize(p['name'])} for p in dlist])
    substs['outputPipes'] = '\n'.join(outputPipes)
    substs['mkConnectionMethodRules'] = ''.join(mkConnectionMethodRules)
    substs['indicationMethodRules'] = collectElements(dlist, indicationRuleTemplate, name)
    substs['indicationMethods'] = collectElements(dlist, indicationMethodTemplate, name)
    substs['requestElements'] = collectElements(dlist, requestStructTemplate, name)
    substs['methodRules'] = collectElements(dlist, requestRuleTemplate, name)
    substs['messageSizes'] = collectElements(dlist, messageSizeTemplate, name)
    return substs

def generate_bsv(project_dir, noisyFlag, jsondata):
    generatedPackageNames = []
    for item in jsondata['interfaces']:
        pname = item['name']
        if pname in generatedPackageNames:
            continue
        generatedPackageNames.append(pname)
        fname = os.path.join(project_dir, 'generatedbsv', '%s.bsv' % pname)
        bsv_file = util.createDirAndOpen(fname, 'w')
        bsv_file.write('package %s;\n' % pname)
        extraImports = (['import %s::*;\n' % pn for pn in [item['Package']] ]
                   + ['import %s::*;\n' % i for i in jsondata['globalimports'] if not i in generatedPackageNames])
        bsv_file.write(preambleTemplate % {'extraImports' : ''.join(extraImports)})
        if noisyFlag:
            print 'Writing file ', fname
        
        bsv_file.write(exposedWrapperInterfaceTemplate % fixupSubsts(item, 'Wrapper'))
        bsv_file.write(exposedProxyInterfaceTemplate % fixupSubsts(item, 'Proxy'))
        bsv_file.write('endpackage: %s\n' % pname)
        bsv_file.close()

