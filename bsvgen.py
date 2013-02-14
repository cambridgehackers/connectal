##
## Copyright (C) 2012-2013 Nokia, Inc
##
import os
import math
import re

import AST
import string
import util

preambleTemplate='''
import FIFO::*;
import GetPut::*;
import Connectable::*;
import Clocks::*;
import Adapter::*;
import AxiMasterSlave::*;
import HDMI::*;
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
%(requestElements)s
'''

requestStructTemplate='''
typedef struct {
%(paramStructDeclarations)s
} %(MethodName)s$Request deriving (Bits);
typedef SizeOf#(%(MethodName)s$Request) %(MethodName)s$RequestSize;
Bit#(8) %(methodName)s$Offset = %(channelNumber)s;
'''

dutResponseTemplate='''
%(responseElements)s
'''

responseStructTemplate='''
typedef struct {
    %(methodReturnType)s %(methodName)s$Response;
} %(MethodName)s$Response deriving (Bits);
typedef SizeOf#(%(MethodName)s$Response) %(MethodName)s$ResponseSize;
Bit#(8) %(methodName)s$Offset = %(channelNumber)s;
'''

mkDutTemplate='''

module mk%(Dut)sWrapper%(dut_hdmi_clock_param)s(%(Dut)sWrapper);

    %(Dut)s %(dut)s <- mk%(Dut)s(%(dut_hdmi_clock_arg)s);
    Reg#(Bit#(32)) requestFired <- mkReg(0);
    Reg#(Bit#(32)) responseFired <- mkReg(0);

    Reg#(Bit#(32)) interruptEnableReg <- mkReg(0);
    Reg#(Bool) interrupted <- mkReg(False);
    Reg#(Bool) interruptCleared <- mkReg(False);
    Reg#(Bit#(32)) getWordCount <- mkReg(0);
    Reg#(Bit#(32)) putWordCount <- mkReg(0);
    Reg#(Bit#(32)) underflowCount <- mkReg(0);
    Reg#(Bit#(32)) overflowCount <- mkReg(0);
    PulseWire interruptRequested <- mkPulseWireOR;
    PulseWire interruptPulses[%(channelCount)s];
    for (Bit#(7) i = 0; i < %(channelCount)s; i = i + 1)
        interruptPulses[i] <- mkPulseWire;

    rule interrupted_rule;
        interrupted <= interruptRequested;
    endrule
    rule reset_interrupt_cleared_rule if (!interrupted);
        interruptCleared <= False;
    endrule

    Reg#(Bit#(12)) ctrlReadAddrReg <- mkReg(0);
    Reg#(Bit#(20)) fifoReadAddrReg <- mkReg(0);
    Reg#(Bit#(12)) ctrlWriteAddrReg <- mkReg(0);
    Reg#(Bit#(16)) fifoWriteAddrReg <- mkReg(0);
    FIFO#(Bit#(8)) fifoWriteAddrFifo <- mkSizedFIFO(4);
    FIFO#(Bit#(32)) fifoWriteDataFifo <- mkSizedFIFO(4);
    FIFO#(Bit#(16)) fifoReadAddrFifo <- mkSizedFIFO(4);
    FIFO#(Bit#(32)) fifoReadDataFifo <- mkSizedFIFO(4);
    FIFO#(Bit#(1)) fifoReadLastFifo <- mkSizedFIFO(4);
    Reg#(Bit#(8)) ctrlReadBurstCountReg <- mkReg(0);
    Reg#(Bit#(8)) fifoReadBurstCountReg <- mkReg(0);
    Reg#(Bit#(8)) ctrlWriteBurstCountReg <- mkReg(0);
    Reg#(Bit#(8)) fifoWriteBurstCountReg <- mkReg(0);
    FIFO#(Bit#(2)) ctrlBrespFifo <- mkFIFO();
    FIFO#(Bit#(2)) fifoBrespFifo <- mkFIFO();

%(methodRules)s

    rule outOfRangeWrite if (fifoWriteAddrFifo.first >= %(channelCount)s);
        fifoWriteAddrFifo.deq;
        fifoWriteDataFifo.deq;
    endrule
    rule outOfRangeRead if (fifoReadAddrFifo.first[15:8] >= %(channelCount)s);
        fifoReadAddrFifo.deq;
        fifoReadDataFifo.enq(0);
    endrule
    rule fifoReadAddressGenerator if (fifoReadBurstCountReg != 0);
        fifoReadAddrFifo.enq(truncate(fifoReadAddrReg));
        fifoReadAddrReg <= fifoReadAddrReg + 4;
        fifoReadBurstCountReg <= fifoReadBurstCountReg - 1;
        fifoReadLastFifo.enq(fifoReadBurstCountReg == 1 ? 1 : 0);
    endrule
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

                Bit#(32) v = 32'h05a05a0;
                if (addr == 12'h000)
                begin
                    v = 0;
                    v[0] = interrupted ? 1'd1 : 1'd0 ;
                end
                if (addr == 12'h004)
                    v = interruptEnableReg;
                if (addr == 12'h008)
                    v = %(channelCount)s; // channelCount
                if (addr == 12'h00C)
                    v = 32'h00010000; // base fifo offset
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
                         //| (responseFifo.notFull ? 32'h20 : 0) | (responseFifo.notEmpty ? 32'h10 : 0)
                         //| (requestFifo.notFull ? 32'h02 : 0) | (requestFifo.notEmpty ? 32'h01 : 0)
                         | extend(fifoReadBurstCountReg)
                         );
                if (addr == 12'h024)
                    v = putWordCount;
                if (addr == 12'h028)
                    v = getWordCount;
                if (addr == 12'h02C)
                    v = 0;
                if (addr >= 12'h030 && addr <= (12'h030 + %(channelCount)s/4))
                begin
                    v = 0;
                    Bit#(7) baseQueueNumber = addr[9:3] << 5;
                    for (Bit#(7) i = 0; i <= baseQueueNumber+31 && i < %(channelCount)s; i = i + 1)
                    begin
                        Bit#(5) bitPos = truncate(i - baseQueueNumber);
                        v[bitPos] = interruptPulses[i] ? 1 : 0;
                    end
                end
                if (addr >= 12'h034 && addr <= (12'h034 + %(channelCount)s/4))
                begin
                    v = 0;
                    %(queuesNotEmpty)s
                end
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
                fifoWriteAddrReg <= fifoWriteAddrReg + 4;
                fifoWriteBurstCountReg <= fifoWriteBurstCountReg - 1;

                fifoWriteAddrFifo.enq(fifoWriteAddrReg[15:8]);
                fifoWriteDataFifo.enq(v);

                putWordCount <= putWordCount + 1;
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
                return fifoReadLastFifo.first;
            endmethod
            method ActionValue#(Bit#(32)) readData();

                let v = fifoReadDataFifo.first;
                fifoReadDataFifo.deq;
                fifoReadLastFifo.deq;

                getWordCount <= getWordCount + 1;
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
    FromBit32#(%(MethodName)s$Request) %(methodName)s$requestFifo <- mkFromBit32();
    rule fifoWrite$%(methodName)s if (fifoWriteAddrFifo.first == %(methodName)s$Offset);
        fifoWriteAddrFifo.deq;
        fifoWriteDataFifo.deq;
        %(methodName)s$requestFifo.enq(fifoWriteDataFifo.first);
    endrule
    rule handle$%(methodName)s$request;
        let request = %(methodName)s$requestFifo.first;
        %(methodName)s$requestFifo.deq;
        %(dut)s.%(methodName)s(%(paramsForCall)s);
        requestFired <= requestFired + 1;
    endrule
    rule %(methodName)s$fifoRead if (fifoReadAddrFifo.first[15:8] == %(methodName)s$Offset);
        fifoReadAddrFifo.deq;
        // nothing to read from a request fifo
        fifoReadDataFifo.enq(0);
    endrule
'''

responseRuleTemplate='''
    ToBit32#(%(methodReturnType)s) %(methodName)s$responseFifo <- mkToBit32();
    rule %(methodName)s$response;
        %(methodReturnType)s response <- %(dut)s.%(methodName)s();
        %(methodName)s$responseFifo.enq(response);
        responseFired <= responseFired + 1;
    endrule
    rule %(methodName)s$fifoRead if (fifoReadAddrFifo.first[15:8] == %(methodName)s$Offset);
        fifoReadAddrFifo.deq;
        Bit#(8) offset = fifoReadAddrFifo.first[7:0];
        Bit#(32) response = 0;
        if (offset == 0)
            response = %(methodName)s$responseFifo.depth32();
        if (offset == 4)
            response = %(methodName)s$responseFifo.count32();
        if (offset >= 128)
        begin
            let maybeResponse = %(methodName)s$responseFifo.first;
            if (maybeResponse matches tagged Valid .v)
            begin
                response = v;
                %(methodName)s$responseFifo.deq;
            end
            else
            begin
                response = 32'h5abeef5a;
                underflowCount <= underflowCount + 1;
            end
        end
        fifoReadDataFifo.enq(response);
    endrule
    rule interrupt$%(methodName)s$Response if (%(methodName)s$responseFifo.notEmpty);
        interruptPulses[%(channelNumber)s].send();
        interruptRequested.send();
    endrule
    rule fifoWrite$%(methodName)s if (fifoWriteAddrFifo.first == %(methodName)s$Offset);
        fifoWriteAddrFifo.deq;
        fifoWriteDataFifo.deq;
        // ignore writes to response fifo
    endrule
'''

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
        if len(self.params):
            return '%s#(%s)' % (self.name, self.params[0].numeric())
        else:
            return self.name
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

    def collectMethodRule(self, outerTypeName):
        substs = self.substs(outerTypeName)
        if self.return_type.name == 'Action':
            paramsForCall = ['request.%s' % p.name for p in self.params]
            substs['paramsForCall'] = ', '.join(paramsForCall)

            return requestRuleTemplate % substs
        else:
            return responseRuleTemplate % substs

class InterfaceMixin:
    def emitBsvImplementation(self, f):
        print self.name
        requestElements = self.collectRequestElements(self.name)
        responseElements = self.collectResponseElements(self.name)
        methodRules = self.collectMethodRules(self.name)
        axiMasters = self.collectInterfaceNames('Axi3?Master')
        axiSlaves = self.collectInterfaceNames('AxiSlave')
        hdmiInterfaces = self.collectInterfaceNames('HDMI')
        dutName = util.decapitalize(self.name)
        methods = [d for d in self.decls if d.type == 'Method']
        substs = {
            'dut': dutName,
            'Dut': util.capitalize(self.name),
            'requestElements': ''.join(requestElements),
            'responseElements': ''.join(responseElements),
            'methodRules': ''.join(methodRules),
            'channelCount': self.channelCount,
            'axiMasterDeclarations': '\n'.join(['    interface %s#(%s,%s) %s;' % (t, params[0].numeric(), params[1].numeric(), axiMaster)
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
            'queuesNotEmpty': '\n'.join(['                    v[%d] = %s$%s.notEmpty ? 1 : 0;'
                                        % (i, methods[i].name, 'requestFifo' if methods[i].params else 'responseFifo')
                                         for i in range(len(methods))])
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
    def collectMethodRules(self,outerTypeName):
        methodRules = []
        for m in self.decls:
            if m.type == 'Method':
                methodRules.append(m.collectMethodRule(outerTypeName))
        return methodRules
    def collectInterfaceNames(self, name):
        interfaceNames = []
        for m in self.decls:
            if m.type == 'Interface':
                #print ("interface name: {%s}" % (m.name)), m
                #print 'name', name, m.name
                pass
            if m.type == 'Interface' and re.match(name, m.name):
                interfaceNames.append((m.subinterfacename, m.name, m.params))
        return interfaceNames
