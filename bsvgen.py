import os
import math

import AST
import newrt
import syntax
import string

preambleTemplate='''
import GetPut::*;
import Connectable::*;
import Adapter::*;
import AxiMasterSlave::*;
import HDMI::*;
import Clocks::*;
%(extraImports)s

interface DUTWrapper;
   method Bit#(32) requestSize();
   method Bit#(32) responseSize();
   interface Reg#(Bit#(32)) reqCount;
   interface Reg#(Bit#(32)) respCount;
   interface Reg#(Bit#(32)) junkReqCount;
   interface Reg#(Bit#(32)) blockedRequestsDiscardedCount;
   interface Reg#(Bit#(32)) blockedResponsesDiscardedCount;

   interface AxiMasterWrite#(64,8) axiw0;
   interface AxiMasterRead#(64) axir0;
   interface AxiMasterWrite#(64,8) axiw1;
   interface AxiMasterRead#(64) axir1;
   interface HDMI hdmi;
endinterface
'''

dutRequestTemplate='''
typedef union tagged {
%(requestElements)s
  Bit#(0) DutRequestUnused;
} DutRequest deriving (Bits);
'''

requestStructTemplate='''
    struct {
%(paramStructDeclarations)s
    } %(MethodName)s$Request;
'''

dutResponseTemplate='''
typedef union tagged {
%(responseElements)s
  Bit#(0) DutResponseUnused;
} DutResponse deriving (Bits);
'''

responseStructTemplate='''
    %(methodReturnType)s %(MethodName)s$Response;
'''

mkDutTemplate='''
module mkDUTWrapper#(Clock axis_clk, FromBit32#(DutRequest) requestFifo, ToBit32#(DutResponse) responseFifo)(DUTWrapper) provisos(Bits#(DutRequest,dutRequestSize),Bits#(DutResponse,dutResponseSize));

    DUT dut <- mkDUT(axis_clk);
    Reg#(Bit#(32)) requestFired <- mkReg(0);
    Reg#(Bit#(32)) responseFired <- mkReg(0);
    Reg#(Bit#(32)) junkReqReg <- mkReg(0);
    Reg#(Bit#(16)) requestTimerReg <- mkReg(0);
    Reg#(Bit#(16)) requestTimeLimitReg <- mkReg(maxBound);
    Reg#(Bit#(16)) responseTimerReg <- mkReg(0);
    Reg#(Bit#(16)) responseTimeLimitReg <- mkReg(maxBound);
    Reg#(Bit#(32)) blockedRequestsDiscardedReg <- mkReg(0);
    Reg#(Bit#(32)) blockedResponsesDiscardedReg <- mkReg(0);

    Bit#(%(tagBits)s) maxTag = %(maxTag)s;

    rule handleJunkRequest if (pack(requestFifo.first)[%(tagBits)s+32-1:32] > maxTag);
        requestFifo.deq;
        junkReqReg <= junkReqReg + 1;
    endrule

    rule requestTimer if (requestFifo.notFull);
        requestTimerReg <= requestTimerReg + 1;
    endrule

    rule discardBlockedRequests if (requestTimerReg > requestTimeLimitReg && requestFifo.notEmpty);
        requestFifo.deq;
        blockedRequestsDiscardedReg <= blockedRequestsDiscardedReg + 1;
        requestTimerReg <= 0;
    endrule

    rule responseTimer if (!responseFifo.notFull);
        responseTimerReg <= responseTimerReg + 1;
    endrule

    rule discardBlockedResponses if (responseTimerReg > responseTimeLimitReg && !responseFifo.notFull);
        responseFifo.deq;
        blockedResponsesDiscardedReg <= blockedResponsesDiscardedReg + 1;
        responseTimerReg <= 0;
    endrule
%(responseRules)s
%(requestRules)s
    method Bit#(32) requestSize();
        return pack(fromInteger(valueof(dutRequestSize)));
    endmethod
    method Bit#(32) responseSize();
        return pack(fromInteger(valueof(dutResponseSize)));
    endmethod
    interface Reg reqCount = requestFired;
    interface Reg respCount = responseFired;
    interface Reg junkReqCount = junkReqReg;
    interface Reg blockedRequestsDiscardedCount = blockedRequestsDiscardedReg;
    interface Reg blockedResponsesDiscardedCount = blockedResponsesDiscardedReg;

    interface AxiMasterWrite axiw0 = dut.axiw0;
    interface AxiMasterRead axir0 = dut.axir0;
    interface AxiMasterWrite axiw1 = dut.axiw1;
    interface AxiMasterRead axir1 = dut.axir1;
    interface HDMI hdmi = dut.hdmi;
endmodule
'''

requestRuleTemplate='''
    rule handle$%(methodName)s$request if (requestFifo.first matches tagged %(MethodName)s$Request .sp);
        requestFifo.deq;
        dut.%(methodName)s(%(paramsForCall)s);
        requestFired <= requestFired + 1;
        requestTimerReg <= 0;
    endrule
'''

responseRuleTemplate='''
    rule %(methodName)s$response;
        %(methodReturnType)s r <- dut.%(methodName)s();
        let response = tagged %(MethodName)s$Response r;
        responseFifo.enq(response);
        responseFired <= responseFired + 1;
    endrule
'''

def capitalize(s):
    return '%s%s' % (s[0].upper(), s[1:])

def emitPreamble(f, files):
    extraImports = ['import %s::*;\n' % os.path.splitext(os.path.basename(fn))[0] for fn in files]
    f.write(preambleTemplate % {'extraImports' : ''.join(extraImports)})

class NullMixin:
    def emitBsvImplementation(self, f):
        pass

class TypeMixin:
    def toBsvType(self):
        if self.name.find('#'):
            return '%s(%s)' % (self.name, self.params[0])
        else:
            return self.name
class MethodMixin:
    def emitBsvImplementation(self, f):
        pass
    def substs(self):
        if self.return_type.name == 'ActionValue#':
            rt = self.return_type.params[0].type.toBsvType()
        else:
            rt = self.return_type.name
        d = {'methodName': self.name,
             'MethodName': capitalize(self.name),
             'methodReturnType': rt}
        return d

    def collectRequestElement(self):
        if not self.params:
            return None
        substs = self.substs()
        paramStructDeclarations = ['        %s %s;' % (p.type.toBsvType(), p.name)
                                   for p in self.params]
        substs['paramStructDeclarations'] = '\n'.join(paramStructDeclarations)
        return requestStructTemplate % substs

    def collectResponseElement(self):
        if self.return_type.name == 'Action ':
            return None
        return responseStructTemplate % self.substs()

    def collectRequestRule(self):
        substs = self.substs()
        if self.return_type.name == 'Action ':
            paramsForCall = ['sp.%s' % p.name for p in self.params]
            substs['paramsForCall'] = ', '.join(paramsForCall)
            return requestRuleTemplate % substs
        else:
            return responseRuleTemplate % substs

class InterfaceMixin:
    def emitBsvImplementation(self, f):
        requestElements = self.collectRequestElements()
        responseElements = self.collectResponseElements()
        requestRules = self.collectRequestRules()
        substs = {
            'requestElements': ''.join(requestElements),
            'responseElements': ''.join(responseElements),
            'requestRules': ''.join(requestRules),
            'maxTag': len(requestElements),
            'tagBits': int(math.ceil(math.log(len(requestElements),2))),
            'responseRules': ''
            }
        f.write(dutRequestTemplate % substs)
        f.write(dutResponseTemplate % substs)
        f.write(mkDutTemplate % substs)
    def collectRequestElements(self):
        requestElements = []
        for m in self.decls:
            if m.type == 'Method':
                e = m.collectRequestElement()
                if e:
                    requestElements.append(e)
        return requestElements
    def collectResponseElements(self):
        responseElements = []
        for m in self.decls:
            if m.type == 'Method':
                e = m.collectResponseElement()
                if e:
                    responseElements.append(e)
        return responseElements
    def collectRequestRules(self):
        requestRules = []
        for m in self.decls:
            if m.type == 'Method':
                requestRules.append(m.collectRequestRule())
        return requestRules
