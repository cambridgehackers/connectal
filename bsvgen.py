##
## Copyright (C) 2012-2013 Nokia, Inc
##
import os
import math
import re

import syntax
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
import AxiClientServer::*;
import HDMI::*;
import Zynq::*;
%(extraImports)s

'''

dutInterfaceTemplate='''
interface %(Dut)sWrapper;
   method Bit#(1) interrupt();
   interface Axi3Slave#(32,4) ctrl;
%(axiSlaveDeclarations)s
%(axiMasterDeclarations)s
%(hdmiDeclarations)s
%(ledDeclarations)s
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
%(paramStructDeclarations)s
} %(MethodName)s$Response deriving (Bits);
typedef SizeOf#(%(MethodName)s$Response) %(MethodName)s$ResponseSize;
Bit#(8) %(methodName)s$Offset = %(channelNumber)s;
'''

mkDutTemplate='''

interface %(Dut)sIndicationsWrapper;
    interface %(Dut)sIndications indications;
    interface Reg#(Bit#(32)) underflowCount;
    interface Reg#(Bit#(32)) responseFired;
endinterface

module mk%(Dut)sIndicationsWrapper#(FIFO#(Bit#(17)) axiSlaveWriteAddrFifo, FIFO#(Bit#(17)) axiSlaveReadAddrFifo,
                                    FIFO#(Bit#(32)) axiSlaveWriteDataFifo, FIFO#(Bit#(32)) axiSlaveReadDataFifo,
                                    PulseWire interruptRequested,
                                    PulseWire interruptPulses[]
                                   )
                                   (%(Dut)sIndicationsWrapper);
    Reg#(Bit#(32)) responseFiredReg <- mkReg(0);
    Reg#(Bit#(32)) underflowCountReg <- mkReg(0);

%(indicationMethodRules)s

    interface %(Dut)sIndications indications;
%(indicationMethods)s
    endinterface

    interface Reg responseFired = responseFiredReg;
    interface Reg underflowCount = underflowCountReg;
endmodule

module mk%(Dut)sWrapper%(dut_hdmi_clock_param)s(%(Dut)sWrapper);

    Reg#(Bit#(32)) requestFired <- mkReg(0);

    Reg#(Bit#(32)) interruptEnableReg <- mkReg(0);
    Reg#(Bool) interrupted <- mkReg(False);
    Reg#(Bool) interruptCleared <- mkReg(False);
    Reg#(Bit#(32)) getWordCount <- mkReg(0);
    Reg#(Bit#(32)) putWordCount <- mkReg(0);
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

    Reg#(Bit#(17)) axiSlaveReadAddrReg <- mkReg(0);
    Reg#(Bit#(17)) axiSlaveWriteAddrReg <- mkReg(0);
    Reg#(Bit#(12)) axiSlaveReadIdReg <- mkReg(0);
    Reg#(Bit#(12)) axiSlaveWriteIdReg <- mkReg(0);
    FIFO#(Bit#(17)) axiSlaveWriteAddrFifo <- mkSizedFIFO(4);
    FIFO#(Bit#(17)) axiSlaveReadAddrFifo <- mkSizedFIFO(4);
    FIFO#(Bit#(32)) axiSlaveWriteDataFifo <- mkSizedFIFO(4);
    FIFO#(Bit#(32)) axiSlaveReadDataFifo <- mkSizedFIFO(4);
    FIFO#(Bit#(1)) axiSlaveReadLastFifo <- mkSizedFIFO(4);
    FIFO#(Bit#(12)) axiSlaveReadIdFifo <- mkSizedFIFO(4);
    Reg#(Bit#(4)) axiSlaveReadBurstCountReg <- mkReg(0);
    Reg#(Bit#(4)) axiSlaveWriteBurstCountReg <- mkReg(0);
    Reg#(Bit#(32)) outOfRangeReadCount <- mkReg(0);
    Reg#(Bit#(32)) outOfRangeWriteCount <- mkReg(0);
    FIFO#(Bit#(2)) axiSlaveBrespFifo <- mkFIFO();
    FIFO#(Bit#(12)) axiSlaveBidFifo <- mkFIFO();

    %(Dut)sIndicationsWrapper indWrapper <- mk%(Dut)sIndicationsWrapper(axiSlaveWriteAddrFifo, axiSlaveReadAddrFifo,
                                                                        axiSlaveWriteDataFifo, axiSlaveReadDataFifo,
                                                                        interruptRequested, interruptPulses);
    %(Dut)sIndications indications = indWrapper.indications;

    %(Dut)s %(dut)s <- mk%(Dut)s(%(dut_hdmi_clock_arg)s indications);
%(methodRules)s

    rule writeCtrlReg if (axiSlaveWriteAddrFifo.first[16] == 0);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
	let addr = axiSlaveWriteAddrFifo.first[11:0];
	let v = axiSlaveWriteDataFifo.first;
	if (addr == 12'h000 && v[0] == 1'b1 && interrupted)
	begin
	    interruptCleared <= True;
	end
	if (addr == 12'h004)
	    interruptEnableReg <= v;
    endrule
    rule readCtrlReg if (axiSlaveReadAddrFifo.first[16] == 0);
        axiSlaveReadAddrFifo.deq;
	let addr = axiSlaveReadAddrFifo.first[11:0];

	Bit#(32) v = 32'h05a05a0;
	if (addr == 12'h000)
	begin
	    v = 0;
	    v[0] = interrupted ? 1'd1 : 1'd0 ;
	end
	if (addr == 12'h004)
	    v = interruptEnableReg;
	if (addr == 12'h008)
	    v = 2; // channelCount
	if (addr == 12'h00C)
	    v = 32'h00010000; // base fifo offset
	if (addr == 12'h010)
	    v = requestFired;
	if (addr == 12'h014)
	    v = indWrapper.responseFired;
	if (addr == 12'h018)
	    v = indWrapper.underflowCount;
	if (addr == 12'h01C)
	    v = overflowCount;
	if (addr == 12'h020)
	    v = (32'h68470000
		 //| (responseFifo.notFull ? 32'h20 : 0) | (responseFifo.notEmpty ? 32'h10 : 0)
		 //| (requestFifo.notFull ? 32'h02 : 0) | (requestFifo.notEmpty ? 32'h01 : 0)
		 | extend(axiSlaveReadBurstCountReg)
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
	if (addr == 12'h038)
	begin
	    v = 0;
	end
	if (addr == 12'h03c)
	begin
	    v = outOfRangeReadCount;
	end
	if (addr == 12'h040)
	begin
	    v = outOfRangeWriteCount;
	end
        axiSlaveReadDataFifo.enq(v);
    endrule

    rule outOfRangeWrite if (axiSlaveWriteAddrFifo.first[16] == 1 && axiSlaveWriteAddrFifo.first[15:8] >= %(channelCount)s);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
    endrule
    rule outOfRangeRead if (axiSlaveReadAddrFifo.first[16] == 1 && axiSlaveReadAddrFifo.first[15:8] >= %(channelCount)s);
        axiSlaveReadAddrFifo.deq;
        axiSlaveReadDataFifo.enq(0);
    endrule
    rule axiSlaveReadAddressGenerator if (axiSlaveReadBurstCountReg != 0);
        axiSlaveReadAddrFifo.enq(truncate(axiSlaveReadAddrReg));
        axiSlaveReadAddrReg <= axiSlaveReadAddrReg + 4;
        axiSlaveReadBurstCountReg <= axiSlaveReadBurstCountReg - 1;
        axiSlaveReadLastFifo.enq(axiSlaveReadBurstCountReg == 1 ? 1 : 0);
        axiSlaveReadIdFifo.enq(axiSlaveReadIdReg);
    endrule
%(axiMasterModules)s
    interface Axi3Slave ctrl;
        interface Axi3SlaveWrite write;
            method Action writeAddr(Bit#(32) addr, Bit#(4) burstLen, Bit#(3) burstWidth,
                                    Bit#(2) burstType, Bit#(2) burstProt, Bit#(3) burstCache,
				    Bit#(12) awid)
                          if (axiSlaveWriteBurstCountReg == 0);
                axiSlaveWriteBurstCountReg <= burstLen + 1;
                axiSlaveWriteAddrReg <= truncate(addr);
		axiSlaveWriteIdReg <= awid;
            endmethod
            method Action writeData(Bit#(32) v, Bit#(4) byteEnable, Bit#(1) last)
                          if (axiSlaveWriteBurstCountReg > 0);
                let addr = axiSlaveWriteAddrReg;
                axiSlaveWriteAddrReg <= axiSlaveWriteAddrReg + 4;
                axiSlaveWriteBurstCountReg <= axiSlaveWriteBurstCountReg - 1;

                axiSlaveWriteAddrFifo.enq(axiSlaveWriteAddrReg[16:0]);
                axiSlaveWriteDataFifo.enq(v);

                putWordCount <= putWordCount + 1;
                axiSlaveBrespFifo.enq(0);
                axiSlaveBidFifo.enq(axiSlaveWriteIdReg);
            endmethod
            method ActionValue#(Bit#(2)) writeResponse();
                axiSlaveBrespFifo.deq;
                return axiSlaveBrespFifo.first;
            endmethod
            method ActionValue#(Bit#(12)) bid();
                axiSlaveBidFifo.deq;
                return axiSlaveBidFifo.first;
            endmethod
        endinterface
        interface Axi3SlaveRead read;
            method Action readAddr(Bit#(32) addr, Bit#(4) burstLen, Bit#(3) burstWidth,
                                   Bit#(2) burstType, Bit#(2) burstProt, Bit#(3) burstCache, Bit#(12) arid)
                          if (axiSlaveReadBurstCountReg == 0);
                axiSlaveReadBurstCountReg <= burstLen + 1;
                axiSlaveReadAddrReg <= truncate(addr);
		axiSlaveReadIdReg <= arid;
            endmethod
            method Bit#(1) last();
                return axiSlaveReadLastFifo.first;
            endmethod
            method Bit#(12) rid();
                return axiSlaveReadIdFifo.first;
            endmethod
            method ActionValue#(Bit#(32)) readData();

                let v = axiSlaveReadDataFifo.first;
                axiSlaveReadDataFifo.deq;
                axiSlaveReadLastFifo.deq;
                axiSlaveReadIdFifo.deq;

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
%(ledImplementations)s
endmodule
'''

requestRuleTemplate='''
    FromBit32#(%(MethodName)s$Request) %(methodName)s$requestFifo <- mkFromBit32();
    rule axiSlaveWrite$%(methodName)s if (axiSlaveWriteAddrFifo.first[16] == 1 && axiSlaveWriteAddrFifo.first[15:8] == %(methodName)s$Offset);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        %(methodName)s$requestFifo.enq(axiSlaveWriteDataFifo.first);
    endrule
    rule handle$%(methodName)s$request;
        let request = %(methodName)s$requestFifo.first;
        %(methodName)s$requestFifo.deq;
        %(dut)s.%(methodName)s(%(paramsForCall)s);
        requestFired <= requestFired + 1;
    endrule
    rule %(methodName)s$axiSlaveRead if (axiSlaveReadAddrFifo.first[16] == 1 && axiSlaveReadAddrFifo.first[15:8] == %(methodName)s$Offset);
        axiSlaveReadAddrFifo.deq;
        // nothing to read from a request fifo
        axiSlaveReadDataFifo.enq(0);
    endrule
'''

indicationRuleTemplate='''
    ToBit32#(%(MethodName)s$Response) %(methodName)s$responseFifo <- mkToBit32();
    rule %(methodName)s$axiSlaveRead if (axiSlaveReadAddrFifo.first[16] == 1 && axiSlaveReadAddrFifo.first[15:8] == %(methodName)s$Offset);
        axiSlaveReadAddrFifo.deq;
        Bit#(8) offset = axiSlaveReadAddrFifo.first[7:0];
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
                underflowCountReg <= underflowCountReg + 1;
            end
        end
        axiSlaveReadDataFifo.enq(response);
    endrule
    rule interrupt$%(methodName)s$Response if (%(methodName)s$responseFifo.notEmpty);
        interruptPulses[%(channelNumber)s].send();
        interruptRequested.send();
    endrule
    rule axiSlaveWrite$%(methodName)s if (axiSlaveWriteAddrFifo.first[16] == 1 && axiSlaveWriteAddrFifo.first[15:8] == %(methodName)s$Offset);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        // ignore writes to response fifo
    endrule
'''

indicationMethodTemplate='''
        method Action %(methodName)s(%(formals)s);
            %(methodName)s$responseFifo.enq(%(MethodName)s$Response {%(structElements)s});
            responseFiredReg <= responseFiredReg + 1;
        endmethod
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
        substs = self.substs(outerTypeName)
        paramStructDeclarations = ['        %s %s;' % (p.type.toBsvType(), p.name)
                                   for p in self.params]
        if not self.params:
            paramStructDeclarations = ['        %s %s;' % ('Bit#(32)', 'padding')]

        substs['paramStructDeclarations'] = '\n'.join(paramStructDeclarations)
        return requestStructTemplate % substs

    def collectResponseElement(self, outerTypeName):
        substs = self.substs(outerTypeName)
        paramStructDeclarations = ['        %s %s;' % (p.type.toBsvType(), p.name)
                                   for p in self.params]
        if not self.params:
            paramStructDeclarations = ['        %s %s;' % ('Bit#(32)', 'padding')]
        substs['paramStructDeclarations'] = '\n'.join(paramStructDeclarations)
        return responseStructTemplate % substs

    def collectMethodRule(self, outerTypeName):
        substs = self.substs(outerTypeName)
        if self.return_type.name == 'Action':
            paramsForCall = ['request.%s' % p.name for p in self.params]
            substs['paramsForCall'] = ', '.join(paramsForCall)

            return requestRuleTemplate % substs
        else:
            return None

    def collectIndicationMethodRule(self, outerTypeName):
        substs = self.substs(outerTypeName)
        print 
        if self.return_type.name == 'Action':
            paramType = ['%s' % p.type.toBsvType() for p in self.params]
            substs['paramType'] = ', '.join(paramType)
            return indicationRuleTemplate % substs
        else:
            return None

    def collectIndicationMethod(self, outerTypeName):
        substs = self.substs(outerTypeName)
        print 
        if self.return_type.name == 'Action':
            formal = ['%s %s' % (p.type.toBsvType(), p.name) for p in self.params]
            substs['formals'] = ', '.join(formal)
            structElements = ['%s: %s' % (p.name, p.name) for p in self.params]
            substs['structElements'] = ', '.join(structElements)
            return indicationMethodTemplate % substs
        else:
            return None

class InterfaceMixin:
    def emitBsvImplementation(self, f):
        print self.name
        indicationInterfaceName = '%sIndications' % util.capitalize(self.name)
        indicationInterface = syntax.globalvars[indicationInterfaceName]

        requestElements = self.collectRequestElements(self.name)
        responseElements = indicationInterface.collectResponseElements(self.name)
        methodRules = self.collectMethodRules(self.name)
        indicationMethodRules = indicationInterface.collectIndicationMethodRules(self.name)
        indicationMethods = indicationInterface.collectIndicationMethods(self.name)
        axiMasters = self.collectInterfaceNames('Axi3?Client')
        axiSlaves = self.collectInterfaceNames('AxiSlave')
        hdmiInterfaces = self.collectInterfaceNames('HDMI')
        ledInterfaces = self.collectInterfaceNames('LEDS')
        dutName = util.decapitalize(self.name)
        methods = [d for d in self.decls if d.type == 'Method' and d.return_type.name == 'Action']
        substs = {
            'dut': dutName,
            'Dut': util.capitalize(self.name),
            'requestElements': ''.join(requestElements),
            'responseElements': ''.join(responseElements),
            'methodRules': ''.join(methodRules),
            'indicationMethodRules': ''.join(indicationMethodRules),
            'indicationMethods': ''.join(indicationMethods),
            'channelCount': indicationInterface.channelCount, # includes self.channelCount
            'axiMasterDeclarations': '\n'.join(['    interface Axi3Master#(%s,%s,%s) %s;' % (params[0].numeric(), params[1].numeric(), params[2].numeric(), axiMaster)
                                                for (axiMaster,t,params) in axiMasters]),
            'axiSlaveDeclarations': '\n'.join(['    interface AxiSlave#(32,4) %s;' % axiSlave
                                               for (axiSlave,t,params) in axiSlaves]),
            'hdmiDeclarations': '\n'.join(['    interface HDMI %s;' % hdmi
                                           for (hdmi,t,params) in hdmiInterfaces]),
            'ledDeclarations': '\n'.join(['    interface LEDS %s;' % led
                                          for (led,t,params) in ledInterfaces]),
            'axiMasterModules': '\n'.join(['    Axi3Master#(%s,%s,%s) %sMaster <- mkAxi3Master(%s.%s);'
                                           % (params[0].numeric(), params[1].numeric(), params[2].numeric(), axiMaster,dutName,axiMaster)
                                                   for (axiMaster,t,params) in axiMasters]),
            'axiMasterImplementations': '\n'.join(['    interface Axi3Master %s = %sMaster;' % (axiMaster,axiMaster)
                                                   for (axiMaster,t,params) in axiMasters]),
            'dut_hdmi_clock_param': '#(Clock hdmi_clk)' if len(hdmiInterfaces) else '',
            'dut_hdmi_clock_arg': 'hdmi_clk,' if len(hdmiInterfaces) else '',
            'axiSlaveImplementations': '\n'.join(['    interface AxiSlave %s = %s.%s;' % (axiSlave,dutName,axiSlave)
                                                  for (axiSlave,t,params) in axiSlaves]),
            'hdmiImplementations': '\n'.join(['    interface HDMI %s = %s.%s;' % (hdmi, dutName, hdmi)
                                              for (hdmi,t,params) in hdmiInterfaces]),
            'ledImplementations': '\n'.join(['    interface LEDS %s = %s.%s;' % (led, dutName, led)
                                              for (led,t,params) in ledInterfaces]),
            'queuesNotEmpty': '\n'.join(['                    v[%d] = %s$%s.notEmpty ? 1 : 0;'
                                        % (i, methods[i].name, 'requestFifo' if not self.isIndication else 'responseFifo')
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
                methodRule = m.collectMethodRule(outerTypeName)
                if methodRule:
                    methodRules.append(methodRule)
        return methodRules
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
