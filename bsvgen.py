##
## Copyright (C) 2012-2013 Nokia, Inc
##
import os
import math
import re

import AST
import newrt
import syntax
import string
import xst

preambleTemplate='''
import FIFO::*;
import GetPut::*;
import Connectable::*;
import Adapter::*;
import AxiMasterSlave::*;
import HDMI::*;
import Clocks::*;
%(extraImports)s

'''

dutInterfaceTemplate='''
interface %(Dut)sWrapper;
   method Bit#(1) interrupt();
   interface AxiSlave#(32,4) ctrl;
   interface AxiSlave#(32,4) fifo;
%(axiSlaveDeclarations)s
%(axiMasterDeclarations)s
%(hdmiDeclarations)s
endinterface
'''

dutRequestTemplate='''
typedef union tagged {
%(requestElements)s
  Bit#(0) DutRequestUnused;
} %(Dut)sRequest deriving (Bits);
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
} %(Dut)sResponse deriving (Bits);
'''

responseStructTemplate='''
    %(methodReturnType)s %(MethodName)s$Response;
'''

mkDutTemplate='''
typedef SizeOf#(%(Dut)sRequest) %(Dut)sRequestSize;
typedef SizeOf#(%(Dut)sResponse) %(Dut)sResponseSize;

module mk%(Dut)sWrapper%(dut_hdmi_clock_param)s(%(Dut)sWrapper);

    %(Dut)s %(dut)s <- mk%(Dut)s(%(dut_hdmi_clock_arg)s);
    FromBit32#(%(Dut)sRequest) requestFifo <- mkFromBit32();
    ToBit32#(%(Dut)sResponse) responseFifo <- mkToBit32();
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

    rule requestTimer if (requestFifo.notFull);
        requestTimerReg <= requestTimerReg + 1;
    endrule

    rule responseTimer if (!responseFifo.notFull);
        responseTimerReg <= responseTimerReg + 1;
    endrule

    //rule handleJunkRequest if (pack(requestFifo.first)[%(tagBits)s+32-1:32] > maxTag);
    //    requestFifo.deq;
    //    junkReqReg <= junkReqReg + 1;
    //endrule
%(responseRules)s
%(requestRules)s
    Reg#(Bit#(32)) interruptEnableReg <- mkReg(0);
    Reg#(Bool) interrupted <- mkReg(False);
    Reg#(Bool) interruptCleared <- mkReg(False);
    Reg#(Bit#(32)) getWordCount <- mkReg(0);
    Reg#(Bit#(32)) putWordCount <- mkReg(0);
    Reg#(Bit#(32)) word0Put  <- mkReg(0);
    Reg#(Bit#(32)) word1Put  <- mkReg(0);
    Reg#(Bit#(32)) underflowCount <- mkReg(0);
    Reg#(Bit#(32)) overflowCount <- mkReg(0);

    rule interrupted_rule;
        interrupted <= responseFifo.notEmpty;
    endrule
    rule reset_interrupt_cleared_rule if (!interrupted);
        interruptCleared <= False;
    endrule

    Reg#(Bit#(12)) ctrlReadAddrReg <- mkReg(0);
    Reg#(Bit#(12)) fifoReadAddrReg <- mkReg(0);
    Reg#(Bit#(12)) ctrlWriteAddrReg <- mkReg(0);
    Reg#(Bit#(12)) fifoWriteAddrReg <- mkReg(0);
    Reg#(Bit#(8)) ctrlReadBurstCountReg <- mkReg(0);
    Reg#(Bit#(8)) fifoReadBurstCountReg <- mkReg(0);
    Reg#(Bit#(8)) ctrlWriteBurstCountReg <- mkReg(0);
    Reg#(Bit#(8)) fifoWriteBurstCountReg <- mkReg(0);
    FIFO#(Bit#(2)) ctrlBrespFifo <- mkFIFO();
    FIFO#(Bit#(2)) fifoBrespFifo <- mkFIFO();

    interface AxiSlave ctrl;
        interface AxiSlaveWrite write;
            method Action writeAddr(Bit#(32) addr, Bit#(8) burstLen, Bit#(3) burstWidth,
                                     Bit#(2) burstType, Bit#(3) burstProt, Bit#(4) burstCache)
                          if (ctrlWriteBurstCountReg == 0);
                ctrlWriteBurstCountReg <= burstLen + 1;
                ctrlWriteAddrReg <= truncate(addr);
            endmethod
            method Action writeData(Bit#(32) v, Bit#(4) byteEnable, Bit#(1) last)
                          if (ctrlWriteBurstCountReg > 0);
                let addr = ctrlWriteAddrReg;
                ctrlWriteAddrReg <= ctrlWriteAddrReg + 12'd4;
                ctrlWriteBurstCountReg <= ctrlWriteBurstCountReg - 1;
                if (addr == 12'h000 && v[0] == 1'b1 && interrupted)
                begin
                    interruptCleared <= True;
                end
                if (addr == 12'h004)
                    interruptEnableReg <= v;
                ctrlBrespFifo.enq(0);
            endmethod
            method ActionValue#(Bit#(2)) writeResponse();
                ctrlBrespFifo.deq;
                return ctrlBrespFifo.first;
            endmethod
        endinterface
        interface AxiSlaveRead read;
            method Action readAddr(Bit#(32) addr, Bit#(8) burstLen, Bit#(3) burstWidth,
                                   Bit#(2) burstType, Bit#(3) burstProt, Bit#(4) burstCache)
                          if (ctrlReadBurstCountReg == 0);
                ctrlReadBurstCountReg <= burstLen + 1;
                ctrlReadAddrReg <= truncate(addr);
            endmethod
            method Bit#(1) last();
                return (ctrlReadBurstCountReg == 1) ? 1 : 0;
            endmethod
            method ActionValue#(Bit#(32)) readData()
                          if (ctrlReadBurstCountReg > 0);
                let addr = ctrlReadAddrReg;
                ctrlReadAddrReg <= ctrlReadAddrReg + 12'd4;
                ctrlReadBurstCountReg <= ctrlReadBurstCountReg - 1;

                let v = 32'h05a05a0;
                if (addr == 12'h000)
                begin
                    v = 0;
                    v[0] = interrupted ? 1'd1 : 1'd0 ;
                    v[16] = responseFifo.notFull ? 1'd1 : 1'd0;
                end
                if (addr == 12'h004)
                    v = interruptEnableReg;
                if (addr == 12'h008)
                    v = fromInteger(valueOf(%(Dut)sRequestSize));
                if (addr == 12'h00C)
                    v = fromInteger(valueOf(%(Dut)sResponseSize));
                if (addr == 12'h010)
                    v = requestFired;
                if (addr == 12'h014)
                    v = responseFired;
                if (addr == 12'h018)
                    v = underflowCount;
                if (addr == 12'h01C)
                    v = overflowCount;
                if (addr == 12'h020)
                    v = (32'h68470000
                         | (responseFifo.notFull ? 32'h20 : 0) | (responseFifo.notEmpty ? 32'h10 : 0)
                         | (requestFifo.notFull ? 32'h02 : 0) | (requestFifo.notEmpty ? 32'h01 : 0));
                if (addr == 12'h024)
                    v = putWordCount;
                if (addr == 12'h028)
                    v = getWordCount;
                if (addr == 12'h02C)
                    v = word0Put;
                if (addr == 12'h030)
                    v = word1Put;
                if (addr == 12'h034)
                    v = junkReqReg;
                if (addr == 12'h038)
                    v = blockedRequestsDiscardedReg;
                if (addr == 12'h03C)
                    v = blockedResponsesDiscardedReg;
                return v;
            endmethod
        endinterface
    endinterface

    interface AxiSlave fifo;
        interface AxiSlaveWrite write;
            method Action writeAddr(Bit#(32) addr, Bit#(8) burstLen, Bit#(3) burstWidth,
                                    Bit#(2) burstType, Bit#(3) burstProt, Bit#(4) burstCache)
                          if (fifoWriteBurstCountReg == 0);
                fifoWriteBurstCountReg <= burstLen + 1;
                fifoWriteAddrReg <= truncate(addr);
            endmethod
            method Action writeData(Bit#(32) v, Bit#(4) byteEnable, Bit#(1) last)
                          if (fifoWriteBurstCountReg > 0);
                let addr = fifoWriteAddrReg;
                fifoWriteAddrReg <= fifoWriteAddrReg + 12'd4;
                fifoWriteBurstCountReg <= fifoWriteBurstCountReg - 1;

                word0Put <= word1Put;
                word1Put <= v;
                if (requestFifo.notFull)
                begin
                    putWordCount <= putWordCount + 1;
                    requestFifo.enq(v);
                end
                else
                begin
                    overflowCount <= overflowCount + 1;
                end
                fifoBrespFifo.enq(0);
            endmethod
            method ActionValue#(Bit#(2)) writeResponse();
                fifoBrespFifo.deq;
                return fifoBrespFifo.first;
            endmethod
        endinterface
        interface AxiSlaveRead read;
            method Action readAddr(Bit#(32) addr, Bit#(8) burstLen, Bit#(3) burstWidth,
                                   Bit#(2) burstType, Bit#(3) burstProt, Bit#(4) burstCache)
                          if (fifoReadBurstCountReg == 0);
                fifoReadBurstCountReg <= burstLen + 1;
                fifoReadAddrReg <= truncate(addr);
            endmethod
            method Bit#(1) last();
                return (fifoReadBurstCountReg == 1) ? 1 : 0;
            endmethod
            method ActionValue#(Bit#(32)) readData()
                          if (fifoReadBurstCountReg > 0);
                let addr = fifoReadAddrReg;
                fifoReadAddrReg <= fifoReadAddrReg + 12'd4;
                fifoReadBurstCountReg <= fifoReadBurstCountReg - 1;
                let v = 32'h050a050a;
                if (responseFifo.notEmpty)
                begin
                    let r = responseFifo.first(); 
                    if (r matches tagged Valid .b) begin
                        v = b;
                        responseFifo.deq;
                        getWordCount <= getWordCount + 1;
                    end
                end
                else
                begin
                    underflowCount <= underflowCount + 1;
                end
                return v;
            endmethod
        endinterface
    endinterface

    method Bit#(1) interrupt();
        if (interruptEnableReg[0] == 1'd1 && !interruptCleared)
            return interrupted ? 1'd1 : 1'd0;
        else
            return 1'd0;
    endmethod

%(axiSlaveImplementations)s
%(axiMasterImplementations)s
%(hdmiImplementations)s
endmodule
'''

requestRuleTemplate='''
    rule handle$%(methodName)s$request if (requestFifo.first matches tagged %(MethodName)s$Request .sp);
        requestFifo.deq;
        %(dut)s.%(methodName)s(%(paramsForCall)s);
        requestFired <= requestFired + 1;
        requestTimerReg <= 0;
    endrule
'''

responseRuleTemplate='''
    rule %(methodName)s$response;
        %(methodReturnType)s r <- %(dut)s.%(methodName)s();
        let response = tagged %(MethodName)s$Response r;
        responseFifo.enq(response);
        responseFired <= responseFired + 1;
    endrule
'''

def capitalize(s):
    return '%s%s' % (s[0].upper(), s[1:])
def decapitalize(s):
    return '%s%s' % (s[0].lower(), s[1:])

def emitPreamble(f, files):
    extraImports = ['import %s::*;\n' % os.path.splitext(os.path.basename(fn))[0] for fn in files]
    #axiMasterDecarations = ['interface AxiMaster#(64,8) %s;' % axiMaster for axiMaster in axiMasterNames]
    #axiSlaveDecarations = ['interface AxiSlave#(32,4) %s;' % axiSlave for axiSlave in axiSlaveNames]
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
    def substs(self, outerTypeName):
        if self.return_type.name == 'ActionValue#':
            rt = self.return_type.params[0].type.toBsvType()
        else:
            rt = self.return_type.name
        d = { 'dut': decapitalize(outerTypeName),
              'Dut': capitalize(outerTypeName),
              'methodName': self.name,
              'MethodName': capitalize(self.name),
              'methodReturnType': rt}
        return d

    def collectRequestElement(self, outerTypeName):
        if not self.params:
            return None
        substs = self.substs(outerTypeName)
        paramStructDeclarations = ['        %s %s;' % (p.type.toBsvType(), p.name)
                                   for p in self.params]
        substs['paramStructDeclarations'] = '\n'.join(paramStructDeclarations)
        return requestStructTemplate % substs

    def collectResponseElement(self, outerTypeName):
        if self.return_type.name == 'Action':
            return None
        return responseStructTemplate % self.substs(outerTypeName)

    def collectRequestRule(self, outerTypeName):
        substs = self.substs(outerTypeName)
        if self.return_type.name == 'Action':
            paramsForCall = ['sp.%s' % p.name for p in self.params]
            substs['paramsForCall'] = ', '.join(paramsForCall)

            return requestRuleTemplate % substs
        else:
            return responseRuleTemplate % substs

class InterfaceMixin:
    def emitBsvImplementation(self, f):
        print self.name
        requestElements = self.collectRequestElements(self.name)
        responseElements = self.collectResponseElements(self.name)
        requestRules = self.collectRequestRules(self.name)
        axiMasters = self.collectInterfaceNames('Axi3?Master#')
        axiSlaves = self.collectInterfaceNames('AxiSlave#')
        hdmiInterfaces = self.collectInterfaceNames('HDMI')
        dutName = decapitalize(self.name)
        substs = {
            'dut': dutName,
            'Dut': capitalize(self.name),
            'requestElements': ''.join(requestElements),
            'responseElements': ''.join(responseElements),
            'requestRules': ''.join(requestRules),
            'maxTag': len(requestElements),
            'tagBits': int(math.ceil(math.log(len(requestElements)+1,2))),
            'axiMasterDeclarations': '\n'.join(['    interface %s(%s,%s) %s;' % (t, params[0], params[1], axiMaster)
                                                for (axiMaster,t,params) in axiMasters]),
            'axiSlaveDeclarations': '\n'.join(['    interface AxiSlave#(32,4) %s;' % axiSlave
                                               for (axiSlave,t,params) in axiSlaves]),
            'hdmiDeclarations': '\n'.join(['    interface HDMI %s;' % hdmi
                                           for (hdmi,t,params) in hdmiInterfaces]),
            'axiMasterImplementations': '\n'.join(['    interface %s %s = %s.%s;' % (t[0:-1], axiMaster,dutName,axiMaster)
                                                   for (axiMaster,t,params) in axiMasters]),
            'dut_hdmi_clock_param': '#(Clock hdmi_clk)' if len(hdmiInterfaces) else '',
            'dut_hdmi_clock_arg': 'hdmi_clk' if len(hdmiInterfaces) else '',
            'axiSlaveImplementations': '\n'.join(['    interface AxiSlave %s = %s.%s;' % (axiSlave,dutName,axiSlave)
                                                  for (axiSlave,t,params) in axiSlaves]),
            'hdmiImplementations': '\n'.join(['    interface HDMI %s = %s.%s;' % (hdmi, dutName, hdmi)
                                              for (hdmi,t,params) in hdmiInterfaces]),
            'responseRules': ''
            }
        f.write(dutRequestTemplate % substs)
        f.write(dutResponseTemplate % substs)
        f.write(dutInterfaceTemplate % substs)
        f.write(mkDutTemplate % substs)
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
    def collectRequestRules(self,outerTypeName):
        requestRules = []
        for m in self.decls:
            if m.type == 'Method':
                requestRules.append(m.collectRequestRule(outerTypeName))
        return requestRules
    def collectInterfaceNames(self, name):
        interfaceNames = []
        for m in self.decls:
            if m.type == 'Interface':
                print ("interface name: {%s}" % (m.name)), m
            if m.type == 'Interface' and re.match(name, m.name):
                interfaceNames.append((m.subinterfacename, m.name, m.params))
        return interfaceNames
