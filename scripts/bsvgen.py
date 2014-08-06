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

import syntax
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
import PortalMemory::*;
import Portal::*;
import MemPortal::*;
import MemTypes::*;
import Pipe::*;
%(extraImports)s

'''

requestStructTemplate='''
typedef struct {
%(paramStructDeclarations)s
} %(MethodName)s_Request deriving (Bits);
Bit#(6) %(methodName)s_Offset = %(channelNumber)s;
'''

requestOutputPipeInterfaceTemplate='''\
    interface PipeOut#(%(MethodName)s_Request) %(methodName)s_PipeOut;
'''

exposedProxyInterfaceTemplate='''
%(responseElements)s
// exposed proxy interface
interface %(Dut)sPortal;
    interface Portal#(%(requestChannelCount)s, %(indicationChannelCount)s, 32) portalIfc;
    interface %(Ifc)s ifc;
endinterface
interface %(Dut)s;
    interface StdPortal portalIfc;
    interface %(Ifc)s ifc;
endinterface

(* synthesize *)
module %(moduleContext)s mk%(Dut)sPortalSynth#(Bit#(32) id) (%(Dut)sPortal);
    Vector#(0, PipeIn#(Bit#(32))) requestPipes = nil;
    Vector#(0, Bit#(32))          requestBits = nil;
    Vector#(%(channelCount)s, PipeOut#(Bit#(32))) indicationPipes = newVector();
    Vector#(%(channelCount)s, Bit#(32))           indicationBits = newVector();
%(indicationMethodRules)s
    interface %(Ifc)s ifc;
%(indicationMethods)s
    endinterface
%(portalIfc)s
endmodule

// exposed proxy implementation
module %(moduleContext)s mk%(Dut)sPortal#(idType id) (%(Dut)sPortal)
    provisos (Bits#(idType, __a),
              Add#(a__, __a, 32));
    let rv <- mk%(Dut)sPortalSynth(extend(pack(id)));
    return rv;
endmodule

// synthesizeable proxy MemPortal
(* synthesize *)
module mk%(Dut)sSynth#(Bit#(32) id)(%(Dut)s);
  let dut <- mk%(Dut)sPortal(id);
  let memPortal <- mkMemPortal(dut.portalIfc);
  interface MemPortal portalIfc = memPortal;
  interface %(Ifc)s ifc = dut.ifc;
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
interface %(Dut)sPipes;
    interface Vector#(%(requestChannelCount)s, PipeIn#(Bit#(32))) inputPipes;
    interface Vector#(%(requestChannelCount)s, Bit#(32)) requestSizeBits;
%(requestOutputPipeInterfaces)s
endinterface
interface %(Dut)sPortal;
    interface Portal#(%(requestChannelCount)s, %(indicationChannelCount)s, 32) portalIfc;
endinterface
// exposed wrapper MemPortal interface
interface %(Dut)s;
    interface StdPortal portalIfc;
endinterface

instance Connectable#(%(Dut)sPipes,%(Ifc)s);
   module mkConnection#(%(Dut)sPipes pipes, %(Ifc)s ifc)(Empty);
%(mkConnectionMethodRules)s
   endmodule
endinstance

// exposed wrapper Portal implementation
(* synthesize *)
module mk%(Dut)sPipes#(Bit#(32) id)(%(Dut)sPipes);
    Vector#(%(requestChannelCount)s, PipeIn#(Bit#(32))) requestPipeIn = newVector();
    Vector#(%(requestChannelCount)s, Bit#(32)) requestBits = newVector();
    Vector#(0, PipeOut#(Bit#(32))) indicationPipes = nil;
    Vector#(0, Bit#(32))           indicationBits = nil;
%(methodRules)s
    interface Vector inputPipes = requestPipeIn;
    interface Vector requestSizeBits = requestBits;
%(outputPipes)s
endmodule

module mk%(Dut)sPortal#(idType id, %(Ifc)s ifc)(%(Dut)sPortal)
    provisos (Bits#(idType, __a),
              Add#(a__, __a, 32));
    let pipes <- mk%(Dut)sPipes(zeroExtend(pack(id)));
    mkConnection(pipes, ifc);
    let requestPipes = pipes.inputPipes;
    let requestBits = pipes.requestSizeBits;
    Vector#(0, PipeOut#(Bit#(32))) indicationPipes = nil;
    Vector#(0, Bit#(32)) indicationBits = nil;
%(portalIfc)s
endmodule

interface %(Dut)sMemPortalPipes;
    interface %(Dut)sPipes pipes;
    interface MemPortal#(16,32) portalIfc;
endinterface

(* synthesize *)
module mk%(Dut)sMemPortalPipes#(Bit#(32) id)(%(Dut)sMemPortalPipes);

  let p <- mk%(Dut)sPipes(zeroExtend(pack(id)));

  Portal#(%(requestChannelCount)s, 0, 32) portalifc = (interface Portal;
        method Bit#(32) ifcId;
            return zeroExtend(pack(id));
        endmethod
        method Bit#(32) ifcType;
            return %(ifcType)s;
        endmethod
        interface Vector requests = p.inputPipes;
        interface Vector requestSizeBits = p.requestSizeBits;
        interface Vector indications = nil;
        interface Vector indicationSizeBits = nil;
    endinterface);

  let memPortal <- mkMemPortal(portalifc);
  interface %(Dut)sPipes pipes = p;
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

responseStructTemplate='''
typedef struct {
%(paramStructDeclarations)s
} %(MethodName)s_Response deriving (Bits);
Bit#(6) %(methodName)s_Offset = %(channelNumber)s;
'''

portalIfcTemplate='''
    interface Portal portalIfc;
        method Bit#(32) ifcId;
            return zeroExtend(pack(id));
        endmethod
        method Bit#(32) ifcType;
            return %(ifcType)s;
        endmethod
        interface Vector requests = requestPipes;
        interface Vector requestSizeBits = requestBits;
        interface Vector indications = indicationPipes;
        interface Vector indicationSizeBits = indicationBits;
    endinterface
'''

requestRuleTemplate='''
    FromBit#(32,%(MethodName)s_Request) %(methodName)s_requestFifo <- mkFromBit();
    requestPipeIn[%(channelNumber)s] = toPipeIn(%(methodName)s_requestFifo);
    requestBits[%(channelNumber)s]  = fromInteger(valueOf(SizeOf#(%(MethodName)s_Request)));
'''

mkConnectionMethodTemplate='''
    rule handle_%(methodName)s_request;
        let request <- toGet(pipes.%(methodName)s_PipeOut).get();
        ifc.%(methodName)s(%(paramsForCall)s);
    endrule
'''

indicationRuleTemplate='''
    ToBit#(32,%(MethodName)s_Response) %(methodName)s_responseFifo <- mkToBit();
    indicationPipes[%(channelNumber)s] = toPipeOut(%(methodName)s_responseFifo);
    indicationBits[%(channelNumber)s]  = fromInteger(valueOf(SizeOf#(%(MethodName)s_Response)));
'''

indicationMethodDeclTemplate='''
    method Action %(methodName)s(%(formals)s);'''

indicationMethodTemplate='''
    method Action %(methodName)s(%(formals)s);
        %(methodName)s_responseFifo.enq(%(MethodName)s_Response {%(structElements)s});
        //$display(\"indicationMethod \'%(methodName)s\' invoked\");
    endmethod'''

class ParamMixin:
    def numBitsBSV(self):
        return self.type.numBitsBSV();

class NullMixin:
    def functionnotused(self):
        pass

class TypeMixin:
    def toBsvType(self):
        if len(self.params):
            return '%s#(%s)' % (self.name, ','.join([str(p.toBsvType()) for p in self.params]))
        else:
            return self.name
    def numBitsBSV(self):
        if (self.name == 'Bit'):
            return self.params[0].numeric()
        if (self.name == 'Vector'):
            return self.params[0].numeric() * self.params[1].numBitsBSV()
        if (self.name == 'Int' or self.name == 'UInt'):
            return self.params[0].numeric()
        if (self.name == 'Float'):
            return 32
	sdef = syntax.globalvars[self.name].tdtype
        if (sdef.type == 'Struct'):
            return sum([e.type.numBitsBSV() for e in sdef.elements])
        else:
            return sdef.numBitsBSV();

class EnumMixin:
    def numBitsBSV(self):
        return int(math.ceil(math.log(len(self.elements),2)))

class MethodMixin:
    def substs(self, outerTypeName):
        if self.return_type.name == 'ActionValue':
            rt = self.return_type.params[0].toBsvType()
        else:
            rt = self.return_type.name
        d = { 'dut': util.decapitalize(outerTypeName),
              'Dut': util.capitalize(outerTypeName),
              'methodName': self.name,
              'MethodName': util.capitalize(self.name),
              'channelNumber': self.channelNumber,
              'ord': self.channelNumber,
              'methodReturnType': rt}
        return d

    def collectRequestElement(self, outerTypeName):
        substs = self.substs(outerTypeName)
        paramStructDeclarations = ['    %s %s;' % (p.type.toBsvType(), p.name)
                                   for p in self.params]
        if not self.params:
            paramStructDeclarations = ['    %s %s;' % ('Bit#(32)', 'padding')]

        substs['paramStructDeclarations'] = '\n'.join(paramStructDeclarations)
        return requestStructTemplate % substs

    def collectResponseElement(self, outerTypeName):
        substs = self.substs(outerTypeName)
        paramStructDeclarations = ['    %s %s;' % (p.type.toBsvType(), p.name)
                                   for p in self.params]
        if not self.params:
            paramStructDeclarations = ['    %s %s;' % ('Bit#(32)', 'padding')]
        substs['paramStructDeclarations'] = '\n'.join(paramStructDeclarations)
        return responseStructTemplate % substs

    def collectMethodRule(self, outerTypeName, hidden=False):
        substs = self.substs(outerTypeName)
        if self.return_type.name == 'Action':
            return requestRuleTemplate % substs
        else:
            return None

    def collectIndicationMethodRule(self, outerTypeName):
        substs = self.substs(outerTypeName)
        if self.return_type.name == 'Action':
            paramType = ['%s' % p.type.toBsvType() for p in self.params]
            substs['paramType'] = ', '.join(paramType)
            return indicationRuleTemplate % substs
        else:
            return None

    def collectIndicationMethod(self, outerTypeName):
        substs = self.substs(outerTypeName)
        if self.return_type.name == 'Action':
            formal = ['%s %s' % (p.type.toBsvType(), p.name) for p in self.params]
            substs['formals'] = ', '.join(formal)
            structElements = ['%s: %s' % (p.name, p.name) for p in self.params]
            if not self.params:
                structElements = ['padding: 0']
            substs['structElements'] = ', '.join(structElements)
            return indicationMethodTemplate % substs
        else:
            return None

class InterfaceMixin:
    def substs(self,suffix,proxy):
        name = "%s%s"%(self.name,suffix)
        dutName = util.decapitalize(name)

        # specific to wrappers
        requestElements = self.collectRequestElements(name)
        methodNames = self.collectMethodNames(name)
        methodRules = self.collectMethodRules(name,False)
        
        # specific to proxies
        responseElements = self.collectResponseElements(name)
        indicationMethodRules = self.collectIndicationMethodRules(name)
        indicationMethods = self.collectIndicationMethods(name)

        m = md5.new()
        m.update(self.name)

        substs = {
            'Ifc': self.name,
            'dut': dutName,
            'Dut': util.capitalize(name),
            'requestElements': ''.join(requestElements),
            'methodNames': methodNames,
            'methodRules': ''.join(methodRules),
            'channelCount': self.channelCount,
            'moduleContext': '',

            'requestChannelCount': len(methodRules) if not proxy else 0,
            'responseElements': ''.join(responseElements),
            'indicationMethodRules': ''.join(indicationMethodRules),
            'indicationMethods': ''.join(indicationMethods),
            'indicationChannelCount': self.channelCount if proxy else 0,
            'indicationInterfaces': ''.join(indicationTemplate % { 'Indication': name }) if not self.hasSource else '',
            }

        substs['ifcType'] = 'truncate(128\'h%s)' % m.hexdigest()
        substs['portalIfc'] = portalIfcTemplate % substs
        substs['requestOutputPipeInterfaces'] = ''.join([requestOutputPipeInterfaceTemplate % {'methodName': methodName,
                                                       'MethodName': util.capitalize(methodName)}
                                                       for methodName in methodNames])
        mkConnectionMethodRules = []
        outputPipes = []
        for m in self.decls:
            if m.type == 'Method' and m.return_type.name == 'Action':
                paramsForCall = ['request.%s' % p.name for p in m.params]
                msubs = {'methodName': m.name,
                         'paramsForCall': ', '.join(paramsForCall)}
                mkConnectionMethodRules.append(mkConnectionMethodTemplate % msubs)
                outputPipes.append('    interface %(methodName)s_PipeOut = toPipeOut(%(methodName)s_requestFifo);' % msubs)
        substs['mkConnectionMethodRules'] = ''.join(mkConnectionMethodRules)
        substs['outputPipes'] = '\n'.join(outputPipes)
        return substs

    def collectRequestElements(self, outerTypeName):
        requestElements = []
        for m in self.decls:
            if m.type == 'Method':
                e = m.collectRequestElement(outerTypeName)
                if e:
                    requestElements.append(e)
        return requestElements
    def collectResponseElements(self, outerTypeName):
        responseElements = []
        for m in self.decls:
            if m.type == 'Method':
                e = m.collectResponseElement(outerTypeName)
                if e:
                    responseElements.append(e)
        return responseElements
    def collectMethodRules(self,outerTypeName,hidden):
        methodRules = []
        for m in self.decls:
            if m.type == 'Method':
                methodRule = m.collectMethodRule(outerTypeName,hidden)
                if methodRule:
                    methodRules.append(methodRule)
        return methodRules
    def collectMethodNames(self,outerTypeName):
        methodRuleNames = []
        for m in self.decls:
            if m.type == 'Method':
                methodRule = m.collectMethodRule(outerTypeName)
                if methodRule:
                    methodRuleNames.append(m.name)
                else:
                    print 'method %s has no rule' % m.name
        return methodRuleNames
    def collectIndicationMethodRules(self,outerTypeName):
        methodRules = []
        for m in self.decls:
            if m.type == 'Method':
                methodRule = m.collectIndicationMethodRule(outerTypeName)
                if methodRule:
                    methodRules.append(methodRule)
        return methodRules
    def collectIndicationMethods(self,outerTypeName):
        methods = []
        for m in self.decls:
            if m.type == 'Method':
                methodRule = m.collectIndicationMethod(outerTypeName)
                if methodRule:
                    methods.append(methodRule)
        return methods

def generate_bsv(project_dir, noisyFlag, hwProxies, hwWrappers, dutname):
    def create_bsv_package(pname, data, files):
        fname = os.path.join(project_dir, 'sources', dutname.lower(), '%s.bsv' % pname)
        bsv_file = util.createDirAndOpen(fname, 'w')
        bsv_file.write('package %s;\n' % pname)
        extraImports = (['import %s::*;\n' % os.path.splitext(os.path.basename(fn))[0] for fn in files]
                   + ['import %s::*;\n' % i for i in syntax.globalimports ])
        bsv_file.write(preambleTemplate % {'extraImports' : ''.join(extraImports)})
        if noisyFlag:
            print 'Writing file ', fname
        bsv_file.write(data)
        bsv_file.write('endpackage: %s\n' % pname)
        bsv_file.close()

    for i in hwWrappers:
        create_bsv_package('%sWrapper' % i.name, exposedWrapperInterfaceTemplate % i.substs('Wrapper',False), i.package)
        
    for i in hwProxies:
        create_bsv_package('%sProxy' % i.name, exposedProxyInterfaceTemplate % i.substs("Proxy",True), i.package)

