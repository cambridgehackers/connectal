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
import FIFOF::*;
import GetPut::*;
import Connectable::*;
import Clocks::*;
import Adapter::*;
import AxiMasterSlave::*;
import AxiClientServer::*;
import HDMI::*;
import Zynq::*;
import Imageon::*;
import Vector::*;
%(extraImports)s

'''

exposedInterfaces = ['HDMI', 'LEDS', 'ImageonVita', 'FmcImageonInterface']

dutInterfaceTemplate='''
interface %(Dut)sWrapper;
   method Bit#(1) interrupt();
   interface Axi3Slave#(32,4) ctrl;
%(axiSlaveDeclarations)s
%(axiMasterDeclarations)s
%(exposedInterfaceDeclarations)s
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

interface %(Dut)sIndications$Aug;
%(indicationMethodDecls)s
endinterface

function %(Dut)sIndications strip$Aug(%(Dut)sIndications$Aug aug);
return (interface %(Dut)sIndications;
          %(indicationMethodStripAugs)s
        endinterface);
endfunction

interface %(Dut)sIndicationsWrapper;
    interface %(Dut)sIndications$Aug indications;
    interface Reg#(Bit#(32)) underflowCount;
    interface Reg#(Bit#(32)) responseFiredCnt;
    interface Reg#(Bit#(32)) outOfRangeReadCount;
endinterface

module mk%(Dut)sIndicationsWrapper#(FIFO#(Bit#(17)) axiSlaveReadAddrFifo,
                                    FIFO#(Bit#(32)) axiSlaveReadDataFifo,
                                    Vector#(%(indicationChannelCount)s, PulseWire) readOutstanding )
                                   (%(Dut)sIndicationsWrapper);
    Reg#(Bit#(32)) responseFiredCntReg <- mkReg(0);
    Vector#(%(indicationChannelCount)s, PulseWire) responseFiredWires <- replicateM(mkPulseWire);
    Reg#(Bit#(32)) outOfRangeReadCountReg <- mkReg(0);

    Reg#(Bit#(32)) underflowCountReg <- mkReg(0);

    function Bit#(32) read_wire (PulseWire a) = a._read ? 32'b1 : 32'b0;
    function Bit#(32) my_add(Bit#(32) a, Bit#(32) b) = a+b;
    
    rule increment_responseFiredCntReg;
       responseFiredCntReg <= responseFiredCntReg + fold(my_add, map(read_wire, responseFiredWires));
    endrule
    
%(indicationMethodRules)s

    rule outOfRangeRead if (axiSlaveReadAddrFifo.first[16] == 1 && axiSlaveReadAddrFifo.first[15:8] >= %(indicationChannelCount)s);
        axiSlaveReadAddrFifo.deq;
        axiSlaveReadDataFifo.enq(0);
        outOfRangeReadCountReg <= outOfRangeReadCountReg+1;
    endrule
    interface %(Dut)sIndications$Aug indications;
%(indicationMethods)s
    endinterface
    interface Reg outOfRangeReadCount = outOfRangeReadCountReg;
    interface Reg responseFiredCnt = responseFiredCntReg;
    interface Reg underflowCount = underflowCountReg;
endmodule

module mk%(Dut)sWrapper%(dut_hdmi_clock_param)s(%(Dut)sWrapper);

    Reg#(Bit#(32)) requestFiredCntReg <- mkReg(0);
    Vector#(%(writeChannelCount)s, PulseWire) requestFiredWires <- replicateM(mkPulseWire);

    Reg#(Bit#(32)) getWordCount <- mkReg(0);
    Reg#(Bit#(32)) putWordCount <- mkReg(0);
    Reg#(Bit#(32)) overflowCount <- mkReg(0);

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
    Reg#(Bit#(32)) outOfRangeWriteCount <- mkReg(0);
    FIFO#(Bit#(2)) axiSlaveBrespFifo <- mkFIFO();
    FIFO#(Bit#(12)) axiSlaveBidFifo <- mkFIFO();
    
    Vector#(%(indicationChannelCount)s, PulseWire) readOutstanding <- replicateM(mkPulseWire);
    
    %(Dut)sIndicationsWrapper indWrapper <- mk%(Dut)sIndicationsWrapper(axiSlaveReadAddrFifo,
                                                                        axiSlaveReadDataFifo,
                                                                        readOutstanding);
    %(Dut)sIndications$Aug indications$Aug = indWrapper.indications;
    %(Dut)sIndications     indications     = strip$Aug(indications$Aug);


    %(Dut)s %(dut)s <- mk%(Dut)s(%(dut_hdmi_clock_arg)s indications);

    function Bool my_or(Bool a, Bool b) = a || b;
    function Bool read_wire (PulseWire a) = a._read;
    
    Reg#(Bool) interruptEnableReg <- mkReg(False);
    let       interruptStatus = fold(my_or, map(read_wire, readOutstanding));

    function Bit#(32) read_wire_cvt (PulseWire a) = a._read ? 32'b1 : 32'b0;
    function Bit#(32) my_add(Bit#(32) a, Bit#(32) b) = a+b;

    rule increment_requestFiredCntReg;
       requestFiredCntReg <= requestFiredCntReg + fold(my_add, map(read_wire_cvt, requestFiredWires));
    endrule

%(methodRules)s

    rule writeCtrlReg if (axiSlaveWriteAddrFifo.first[16] == 0);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
	let addr = axiSlaveWriteAddrFifo.first[11:0];
	let v = axiSlaveWriteDataFifo.first;
	if (addr == 12'h000)
	    noAction; // interruptStatus is read-only
	if (addr == 12'h004)
	    interruptEnableReg <= v[0] == 1'd1; //reduceOr(v) == 1'd1;
    endrule
    rule readCtrlReg if (axiSlaveReadAddrFifo.first[16] == 0);
        axiSlaveReadAddrFifo.deq;
	let addr = axiSlaveReadAddrFifo.first[11:0];

	Bit#(32) v = 32'h05a05a0;
	if (addr == 12'h000)
	    v = interruptStatus ? 32'd1 : 32'd0;
	if (addr == 12'h004)
	    v = interruptEnableReg ? 32'd1 : 32'd0;
	if (addr == 12'h008)
	    v = %(indicationChannelCount)s; // indicationChannelCount
	if (addr == 12'h00C)
	    v = 32'h00010000; // base fifo offset
	if (addr == 12'h010)
	    v = requestFiredCntReg;
	if (addr == 12'h014)
	    v = indWrapper.responseFiredCnt;
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
        if (addr == 12'h030)
	    v = indWrapper.outOfRangeReadCount;
	if (addr == 12'h034)
	    v = outOfRangeWriteCount;
        if (addr == 12'h038)
            v = 0; // unused
        if (addr == 12'h03c)
            v = 0; // unused
        if (addr >= 12'h040 && addr <= (12'h040 + %(indicationChannelCount)s/4))
	begin
	    v = 0;
	    Bit#(7) baseQueueNumber = addr[9:3] << 5;
	    for (Bit#(7) i = 0; i <= baseQueueNumber+31 && i < %(indicationChannelCount)s; i = i + 1)
	    begin
		Bit#(5) bitPos = truncate(i - baseQueueNumber);
		// drive value based on which HW->SW FIFOs have pending messages
		v[bitPos] = readOutstanding[i] ? 1'd1 : 1'd0; 
	    end
	end
        axiSlaveReadDataFifo.enq(v);
    endrule

    rule outOfRangeWrite if (axiSlaveWriteAddrFifo.first[16] == 1 && (axiSlaveWriteAddrFifo.first[15:8] < %(indicationChannelCount)s || axiSlaveWriteAddrFifo.first[15:8] >= %(channelCount)s));
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        outOfRangeWriteCount <= outOfRangeWriteCount+1;
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
                                    Bit#(2) burstType, Bit#(3) burstProt, Bit#(4) burstCache,
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
                                   Bit#(2) burstType, Bit#(3) burstProt, Bit#(4) burstCache, Bit#(12) arid)
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
        if (interruptEnableReg && interruptStatus)
            return 1'd1;
        else
            return 1'd0;
    endmethod

%(axiSlaveImplementations)s
%(axiMasterImplementations)s
%(exposedInterfaceImplementations)s
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
        let success = impCondOf(%(dut)s.%(methodName)s(%(paramsForCall)s));
        if (success)
          %(dut)s.%(methodName)s(%(paramsForCall)s);
        else
          indications$Aug.putFailed(%(ord)s);
        requestFiredWires[%(ord)s].send;
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
    rule %(methodName)s$axiSlaveReadOutstanding if (%(methodName)s$responseFifo.notEmpty);
        readOutstanding[%(channelNumber)s].send();
    endrule
'''

indicationMethodDeclTemplate='''
        method Action %(methodName)s(%(formals)s);'''

indicationMethodStripAugTemplate='''
        method Action %(methodName)s(%(formals)s) = aug.%(methodName)s(%(args)s);'''

indicationMethodTemplate='''
        method Action %(methodName)s(%(formals)s);
            %(methodName)s$responseFifo.enq(%(MethodName)s$Response {%(structElements)s});
            responseFiredWires[%(channelNumber)s].send();
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
              'ord': self.ord,
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

    def collectIndicationMethodStripAug(self,outerTypeName):
        substs = self.substs(outerTypeName)
        if (not self.aug):
            formal = ['%s %s' % (p.type.toBsvType(), p.name) for p in self.params]
            arg = ['%s' % (p.name) for p in self.params]
            substs['formals'] = ', '.join(formal)
            substs['args'] = ', '.join(arg)
            structElements = ['%s: %s' % (p.name, p.name) for p in self.params]
            substs['structElements'] = ', '.join(structElements)
            return indicationMethodStripAugTemplate % substs
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
        indicationMethodDecls = indicationInterface.collectIndicationMethodDecls(self.name)
        indicationMethodStripAugs = indicationInterface.collectIndicationMethodStripAugs(self.name)
        axiMasters = self.collectInterfaceNames('Axi3?Client')
        axiSlaves = self.collectInterfaceNames('AxiSlave')
        hdmiInterfaces = self.collectInterfaceNames('HDMI')
        ledInterfaces = self.collectInterfaceNames('LEDS')
        dutName = util.decapitalize(self.name)
        methods = [d for d in self.decls if d.type == 'Method' and d.return_type.name == 'Action']
        buses = {}
        clknames = []
        for busType in exposedInterfaces:
            collected = self.collectInterfaceNames(busType)
            if collected:
                if busType == 'HDMI':
                    clknames.append('hdmi_clk')
            buses[busType] = collected
        print 'clknames', clknames

        substs = {
            'dut': dutName,
            'Dut': util.capitalize(self.name),
            'requestElements': ''.join(requestElements),
            'responseElements': ''.join(responseElements),
            'methodRules': ''.join(methodRules),
            'indicationMethodRules': ''.join(indicationMethodRules),
            'indicationMethods': ''.join(indicationMethods),
            'indicationMethodDecls': ''.join(indicationMethodDecls),
            'indicationMethodStripAugs': ''.join(indicationMethodStripAugs),
            'indicationChannelCount': indicationInterface.channelCount,
            'channelCount': self.channelCount,
            'writeChannelCount': self.channelCount - indicationInterface.channelCount,
            'axiMasterDeclarations': '\n'.join(['    interface Axi3Master#(%s,%s,%s) %s;' % (params[0].numeric(), params[1].numeric(), params[2].numeric(), axiMaster)
                                                for (axiMaster,t,params) in axiMasters]),
            'axiSlaveDeclarations': '\n'.join(['    interface AxiSlave#(32,4) %s;' % axiSlave
                                               for (axiSlave,t,params) in axiSlaves]),
            'exposedInterfaceDeclarations':
                '\n'.join(['\n'.join(['    interface %s %s;' % (t, util.decapitalize(busname))
                                      for (busname,t,params) in buses[busType]])
                           for busType in exposedInterfaces]),
            'axiMasterModules': '\n'.join(['    Axi3Master#(%s,%s,%s) %sMaster <- mkAxi3Master(%s.%s);'
                                           % (params[0].numeric(), params[1].numeric(), params[2].numeric(), axiMaster,dutName,axiMaster)
                                                   for (axiMaster,t,params) in axiMasters]),
            'axiMasterImplementations': '\n'.join(['    interface Axi3Master %s = %sMaster;' % (axiMaster,axiMaster)
                                                   for (axiMaster,t,params) in axiMasters]),
            'dut_hdmi_clock_param': '#(%s)' % ', '.join(['Clock %s' % name for name in clknames]) if len(clknames) else '',
            'dut_hdmi_clock_arg': ' '.join(['%s,' % name for name in clknames]) if len(clknames) else '',
            'axiSlaveImplementations': '\n'.join(['    interface AxiSlave %s = %s.%s;' % (axiSlave,dutName,axiSlave)
                                                  for (axiSlave,t,params) in axiSlaves]),
            'exposedInterfaceImplementations': '\n'.join(['\n'.join(['    interface %s %s = %s.%s;' % (t, busname, dutName, busname)
                                                                     for (busname,t,params) in buses[busType]])
                                                          for busType in exposedInterfaces]),
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
    def collectIndicationMethodDecls(self,outerTypeName):
        methods = []
        for m in self.decls:
            if m.type == 'Method':
                methodRule = m.collectIndicationMethodDecl(outerTypeName)
                if methodRule:
                    methods.append(methodRule)
        return methods
    def collectIndicationMethodStripAugs(self,outerTypeName):
        methods = []
        for m in self.decls:
            if m.type == 'Method':
                methodRule = m.collectIndicationMethodStripAug(outerTypeName)
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
