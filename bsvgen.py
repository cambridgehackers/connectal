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

typedef struct {
    Bit#(1) select;
    Bit#(6) tag;
} ReadReqInfo deriving (Bits);

'''


requestStructTemplate='''
typedef struct {
%(paramStructDeclarations)s
} %(MethodName)s_Request deriving (Bits);
Bit#(6) %(methodName)s_Offset = %(channelNumber)s;
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
'''

hiddenProxyInterfaceTemplate='''
%(responseElements)s
// hidden proxy interface
interface %(Dut)s;
%(indicationMethodDecls)s
    interface ReadOnly#(Bool) interrupt;
endinterface
'''

exposedWrapperInterfaceTemplate='''
%(requestElements)s
// exposed wrapper portal interface
interface %(Dut)sPortal;
    interface Portal#(%(requestChannelCount)s, %(indicationChannelCount)s, 32) portalIfc;
endinterface
// exposed wrapper MemPortal interface
interface %(Dut)s;
    interface StdPortal portalIfc;
endinterface
'''

hiddenWrapperInterfaceTemplate='''
%(requestElements)s
// hidden wrapper interface
interface %(Dut)s;
endinterface
'''

responseStructTemplate='''
typedef struct {
%(paramStructDeclarations)s
} %(MethodName)s_Response deriving (Bits);
Bit#(6) %(methodName)s_Offset = %(channelNumber)s;
'''

wrapperCtrlTemplate='''
%(methodRules)s
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

proxyInterruptImplTemplate='''
    interface ReadOnly interrupt;
        method Bool _read();
            return (interruptEnableReg && interruptStatus);
        endmethod
    endinterface
'''


proxyCtrlTemplate='''
%(indicationMethodRules)s
%(startIndicationMethods)s
%(indicationMethods)s
%(endIndicationMethods)s
'''


requestRuleTemplate='''
    FromBit#(32,%(MethodName)s_Request) %(methodName)s_requestFifo <- mkFromBit();
    requestPipes[%(channelNumber)s] = toPipeIn(%(methodName)s_requestFifo);
    requestBits[%(channelNumber)s]  = fromInteger(valueOf(SizeOf#(%(MethodName)s_Request)));
    rule handle_%(methodName)s_request;
        let request = %(methodName)s_requestFifo.first;
        %(methodName)s_requestFifo.deq;
        %(invokeMethod)s
        //$display("invoked request method %(methodName)s");
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


mkHiddenWrapperInterfaceTemplate='''
// hidden wrapper implementation
module %(moduleContext)s mk%(Dut)s#(FIFO#(Bit#(15)) slaveWriteAddrFifo,
                            FIFO#(Bit#(15)) slaveReadAddrFifo,
                            FIFO#(Bit#(32)) slaveWriteDataFifo,
                            FIFOF#(Bit#(32)) slaveReadDataFifo)(%(Dut)s);
%(wrapperCtrl)s
endmodule
'''

mkExposedWrapperInterfaceTemplate='''
// exposed wrapper Portal implementation
module mk%(Dut)sPortal#(idType id, %(Ifc)s ifc)(%(Dut)sPortal)
    provisos (Bits#(idType, __a), 
              Add#(a__, __a, 32));
    Vector#(%(requestChannelCount)s, PipeIn#(Bit#(32))) requestPipes = newVector();
    Vector#(%(requestChannelCount)s, Bit#(32)) requestBits = newVector();
    Vector#(0, PipeOut#(Bit#(32))) indicationPipes = nil;
    Vector#(0, Bit#(32))           indicationBits = nil;
%(wrapperCtrl)s
%(portalIfc)s
endmodule

// exposed wrapper MemPortal implementation
module mk%(Dut)s#(idType id, %(Ifc)s ifc)(%(Dut)s)
   provisos (Bits#(idType, a__),
	     Add#(b__, a__, 32));
  let dut <- mk%(Dut)sPortal(id, ifc);
  let memSlave <- mkMemPortal(dut.portalIfc);
  interface MemPortal portalIfc = memSlave;
endmodule
'''

mkHiddenProxyInterfaceTemplate='''
// hidden proxy implementation
module %(moduleContext)s mk%(Dut)s#(FIFO#(Bit#(15)) slaveWriteAddrFifo,
                            FIFO#(Bit#(15)) slaveReadAddrFifo,
                            FIFO#(Bit#(32)) slaveWriteDataFifo,
                            FIFOF#(Bit#(32)) slaveReadDataFifo)(%(Dut)s);
%(proxyCtrl)s
%(portalIfcInterrupt)s
endmodule
'''

mkExposedProxyInterfaceTemplate='''
(* synthesize *)
module %(moduleContext)s mk%(Dut)sSynth#(Bit#(32) id) (%(Dut)sPortal);
    Vector#(0, PipeIn#(Bit#(32))) requestPipes = nil;
    Vector#(0, Bit#(32))          requestBits = nil;
    Vector#(%(channelCount)s, PipeOut#(Bit#(32))) indicationPipes = newVector();
    Vector#(%(channelCount)s, Bit#(32))           indicationBits = newVector();
%(proxyCtrl)s
%(portalIfc)s
endmodule

// exposed proxy implementation
module %(moduleContext)s mk%(Dut)sPortal#(idType id) (%(Dut)sPortal)
    provisos (Bits#(idType, __a), 
              Add#(a__, __a, 32));
    let rv <- mk%(Dut)sSynth(extend(pack(id)));
    return rv;
endmodule

// exposed proxy MemPortal
module mk%(Dut)s#(idType id)(%(Dut)s)
   provisos (Bits#(idType, a__),
	     Add#(b__, a__, 32));
  let dut <- mk%(Dut)sPortal(id);
  let memSlave <- mkMemPortal(dut.portalIfc);
  interface MemPortal portalIfc = memSlave;
  interface %(Ifc)s ifc = dut.ifc;
endmodule
'''

def emitPreamble(f, files=[]):
    extraImports = (['import %s::*;\n' % os.path.splitext(os.path.basename(fn))[0] for fn in files]
                   + ['import %s::*;\n' % i for i in syntax.globalimports ])
    f.write(preambleTemplate % {'extraImports' : ''.join(extraImports)})

class ParamMixin:
    def numBitsBSV(self):
        return self.type.numBitsBSV();

class NullMixin:
    def emitBsvImplementation(self, f):
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
    def emitBsvImplementation(self, f):
        pass
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
            paramsForCall = ['request.%s' % p.name for p in self.params]
            substs['paramsForCall'] = ', '.join(paramsForCall)
            substs['putFailed'] = '' if hidden else 'p.putFailed(%(ord)s);' % substs
            substs['invokeMethod'] = '' if hidden else 'ifc.%(methodName)s(%(paramsForCall)s);' % substs
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
            substs['structElements'] = ', '.join(structElements)
            return indicationMethodTemplate % substs
        else:
            return None

    def collectIndicationMethodDecl(self, outerTypeName):
        substs = self.substs(outerTypeName)
        if self.return_type.name == 'Action':
            formal = ['%s %s' % (p.type.toBsvType(), p.name) for p in self.params]
            substs['formals'] = ', '.join(formal)
            structElements = ['%s: %s' % (p.name, p.name) for p in self.params]
            substs['structElements'] = ', '.join(structElements)
            return indicationMethodDeclTemplate % substs
        else:
            return None

class InterfaceMixin:

    def substs(self,suffix,expose,proxy):
        name = "%s%s"%(self.name,suffix)
        dutName = util.decapitalize(name)
        methods = [d for d in self.decls if d.type == 'Method' and d.return_type.name == 'Action']

        # specific to wrappers
        requestElements = self.collectRequestElements(name)
        methodNames = self.collectMethodNames(name)
        methodRuleNames = self.collectMethodRuleNames(name)
        methodRules = self.collectMethodRules(name,not expose)
        
        # specific to proxies
        responseElements = self.collectResponseElements(name)
        indicationMethodRuleNames = self.collectIndicationMethodRuleNames(name)
        indicationMethodRules = self.collectIndicationMethodRules(name)
        indicationMethods = self.collectIndicationMethods(name)
        indicationMethodDecls = self.collectIndicationMethodDecls(name)

        m = md5.new()
        m.update(self.name)

        substs = {
            'dut': dutName,
            'Dut': util.capitalize(name),
            'requestElements': ''.join(requestElements),
            'methodRules': ''.join(methodRules),
            'requestFailureRuleNames': "" if len(methodNames) == 0 else '(* descending_urgency = "'+', '.join(['handle_%s_requestFailure' % n for n in methodNames])+'"*)',
            'channelCount': self.channelCount,
            'writeChannelCount': self.channelCount,
            'Ifc': self.name,
            'hiddenProxy' : "%sStatus" % name,
            'moduleContext': '',

            'requestChannelCount': len(methodRules) if not proxy else 0,
            'responseElements': ''.join(responseElements),
            'indicationMethodRules': ''.join(indicationMethodRules),
            'indicationMethods': ''.join(indicationMethods),
            'indicationMethodDecls' :''.join(indicationMethodDecls),
            'indicationChannelCount': self.channelCount if proxy else 0,
            'indicationInterfaces': ''.join(indicationTemplate % { 'Indication': name }) if not self.hasSource else '',
            'hiddenWrapper' : "%sStatus" % name,
            'startIndicationMethods' : '' if not expose else '    interface %s ifc;' % self.name,
            'endIndicationMethods' : '' if not expose else '    endinterface',
            'slaveFifoSelExposed' : '1' if proxy else '0',
            'slaveFifoSelHidden'  : '0' if proxy else '1',
            }

        substs['portalIfcInterrupt'] = 'interface ReadOnly interrupt = p.interrupt;' if not proxy else proxyInterruptImplTemplate
        substs['ifcType'] = 'truncate(128\'h%s)' % m.hexdigest()
        substs['portalIfc'] = portalIfcTemplate % substs
        substs['wrapperCtrl'] = wrapperCtrlTemplate % substs
        substs['proxyCtrl'] = proxyCtrlTemplate % substs
        return substs

    def emitBsvWrapper(self,f,suffix):
        subs = self.substs(suffix,True,False)
        f.write(exposedWrapperInterfaceTemplate % subs)
        f.write(mkExposedWrapperInterfaceTemplate % subs)

    def emitBsvProxy(self,f,suffix):
        subs = self.substs(suffix,True,True)
        f.write(exposedProxyInterfaceTemplate % subs)
        f.write(mkExposedProxyInterfaceTemplate % subs)

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
    def collectMethodRuleNames(self,outerTypeName):
        methodRuleNames = []
        for m in self.decls:
            if m.type == 'Method':
                methodRule = m.collectMethodRule(outerTypeName)
                if methodRule:
                    methodRuleNames.append('slaveWrite_%s' % m.name)
        return methodRuleNames
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
    def collectIndicationMethodRuleNames(self,outerTypeName):
        methodRuleNames = []
        for m in self.decls:
            if m.type == 'Method':
                methodRule = m.collectIndicationMethodRule(outerTypeName)
                if methodRule:
                    methodRuleNames.append("%s_slaveRead" % m.name)
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
    def collectIndicationMethodDecls(self,outerTypeName):
        methods = []
        for m in self.decls:
            if m.type == 'Method':
                methodRule = m.collectIndicationMethodDecl(outerTypeName)
                if methodRule:
                    methods.append(methodRule)
        return methods
