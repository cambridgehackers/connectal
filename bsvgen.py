##
## Copyright (C) 2012-2013 Nokia, Inc
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
import Adapter::*;
import AxiMasterSlave::*;
import AxiClientServer::*;
import Leds::*;
import Vector::*;
import SpecialFIFOs::*;
import XbsvReadyQueue::*;
import PortalMemory::*;
import Portal::*;
%(extraImports)s

'''


requestStructTemplate='''
typedef struct {
%(paramStructDeclarations)s
} %(MethodName)s$Request deriving (Bits);
Bit#(6) %(methodName)s$Offset = %(channelNumber)s;
'''

exposedProxyInterfaceTemplate='''
%(responseElements)s
// exposed proxy interface
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
// exposed wrapper interface
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
} %(MethodName)s$Response deriving (Bits);
Bit#(6) %(methodName)s$Offset = %(channelNumber)s;
'''

wrapperCtrlTemplate='''
    // request-specific state
    Reg#(Bit#(32)) requestFiredCount <- mkReg(0);
    Reg#(Bit#(32)) outOfRangeWriteCount <- mkReg(0);
    PulseWire requestFiredPulse <- mkPulseWireOR();
    // this is here to get rid of bsv warnings.  
    Reg#(Bool) putEnable <- mkReg(True); 

    rule requestFiredIncrement if (requestFiredPulse);
        requestFiredCount <= requestFiredCount+1;
    endrule

    rule writeCtrlReg if (axiSlaveWriteAddrFifo.first[14] == 1);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
	let addr = axiSlaveWriteAddrFifo.first[13:0];
	let v = axiSlaveWriteDataFifo.first;
	if (addr == 14'h000)
	    noAction;
	if (addr == 14'h004)
	    noAction;
        if (addr == 14'h008)
            putEnable <= v[0] == 1'd1;
    endrule

    rule readCtrlReg if (axiSlaveReadAddrFifo.first[14] == 1);
        axiSlaveReadAddrFifo.deq;
	let addr = axiSlaveReadAddrFifo.first[13:0];
        //$display(\"wrapper readCtrlReg %%h\", addr);
	Bit#(32) v = 32'h05a05a0;
	if (addr == 14'h000)
	    v = requestFiredCount;
	if (addr == 14'h004)
	    v = outOfRangeWriteCount;
%(readAxiState)s
        axiSlaveReadDataFifo.enq(v);
    endrule
    rule readWriteFifo if (axiSlaveReadAddrFifo.first[14] == 0);
        axiSlaveReadAddrFifo.deq;
        axiSlaveReadDataFifo.enq(32'h05b05b0);
    endrule
%(methodRules)s

    %(requestFailureRuleNames)s
    rule outOfRangeWrite if (axiSlaveWriteAddrFifo.first[14] == 0 && 
                             axiSlaveWriteAddrFifo.first[13:8] >= %(channelCount)s);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        outOfRangeWriteCount <= outOfRangeWriteCount+1;
    endrule
'''

portalIfcTemplate='''
    interface StdPortal portalIfc;
    method Bit#(32) ifcId;
        return zeroExtend(pack(id));
    endmethod
    method Bit#(32) ifcType;
        return %(ifcType)s;
    endmethod
    interface Axi3Server ctrl;
        interface Put req_aw;
            method Action put(Axi3WriteRequest#(32, 12) req)
                          if (axiSlaveWriteBurstCountReg == 0);
                 axiSlaveWS <= req.address[15];
                 axiSlaveWriteBurstCountReg <= req.len + 1;
                 axiSlaveWriteAddrReg <= truncate(req.address);
		 axiSlaveWriteIdReg <= req.id;
            endmethod
        endinterface: req_aw
        interface Put resp_write;
            method Action put(Axi3WriteData#(32, 4, 12) wdata)
                          if (axiSlaveWriteBurstCountReg > 0);
                let addr = axiSlaveWriteAddrReg;
                axiSlaveWriteAddrReg <= axiSlaveWriteAddrReg + 4;
                axiSlaveWriteBurstCountReg <= axiSlaveWriteBurstCountReg - 1;

                axiSlaveWriteAddrFifos[axiSlaveWS].enq(axiSlaveWriteAddrReg[14:0]);
                axiSlaveWriteDataFifos[axiSlaveWS].enq(wdata.data);

                putWordCount <= putWordCount + 1;
                if (wdata.last == 1'b1)
                begin
                    axiSlaveBrespFifo.enq(Axi3WriteResponse { resp: 0, id: wdata.id });
                end
            endmethod
        endinterface
        interface Get resp_b;
            method ActionValue#(Axi3WriteResponse#(12)) get();
                axiSlaveBrespFifo.deq;
                return axiSlaveBrespFifo.first;
            endmethod
        endinterface
        interface Put req_ar;
            method Action put(Axi3ReadRequest#(32,12) req)
                          if (axiSlaveReadBurstCountReg == 0);
                 axiSlaveRS <= req.address[15];
                 axiSlaveReadBurstCountReg <= req.len + 1;
                 axiSlaveReadAddrReg <= truncate(req.address);
	    	 axiSlaveReadIdReg <= req.id;
            endmethod
        endinterface
        interface Get resp_read;
            method ActionValue#(Axi3ReadResponse#(32,12)) get();

                let v = axiSlaveReadDataFifos[axiSlaveRS].first;
                axiSlaveReadDataFifos[axiSlaveRS].deq;
                axiSlaveReadLastFifo.deq;
                axiSlaveReadIdFifo.deq;

                getWordCount <= getWordCount + 1;
                return Axi3ReadResponse { data: v, last: axiSlaveReadLastFifo.first, id: axiSlaveReadIdFifo.first, resp: 0 };
            endmethod
        endinterface
    endinterface
%(portalIfcInterrupt)s
    endinterface
'''

proxyInterruptImplTemplate='''
    interface ReadOnly interrupt;
        method Bool _read();
            return (interruptEnableReg && interruptStatus);
        endmethod
    endinterface
'''


readAxiStateTemplate='''
	if (addr == 14'h01C)
	    v = getWordCount;
	if (addr == 14'h020)
	    v = putWordCount;
	if (addr == 14'h024)
	    v = zeroExtend(axiSlaveReadAddrReg);
	if (addr == 14'h028)
	    v = zeroExtend(axiSlaveWriteAddrReg);
	if (addr == 14'h02C)
	    v = zeroExtend(axiSlaveReadIdReg);
	if (addr == 14'h030)
	    v = zeroExtend(axiSlaveWriteIdReg);
	if (addr == 14'h034)
	    v = zeroExtend(axiSlaveReadBurstCountReg);
	if (addr == 14'h038)
	    v = zeroExtend(axiSlaveWriteBurstCountReg);
'''

axiStateTemplate='''
    // state used to implement Axi Slave interface
    Reg#(Bit#(32)) getWordCount <- mkReg(0);
    Reg#(Bit#(32)) putWordCount <- mkReg(0);
    Reg#(Bit#(15)) axiSlaveReadAddrReg <- mkReg(0);
    Reg#(Bit#(15)) axiSlaveWriteAddrReg <- mkReg(0);
    Reg#(Bit#(12)) axiSlaveReadIdReg <- mkReg(0);
    Reg#(Bit#(12)) axiSlaveWriteIdReg <- mkReg(0);
    FIFO#(Bit#(1)) axiSlaveReadLastFifo <- mkPipelineFIFO;
    FIFO#(Bit#(12)) axiSlaveReadIdFifo <- mkPipelineFIFO;
    Reg#(Bit#(4)) axiSlaveReadBurstCountReg <- mkReg(0);
    Reg#(Bit#(4)) axiSlaveWriteBurstCountReg <- mkReg(0);
    FIFO#(Axi3WriteResponse#(12)) axiSlaveBrespFifo <- mkFIFO();

    Vector#(2,FIFO#(Bit#(15))) axiSlaveWriteAddrFifos <- replicateM(mkPipelineFIFO);
    Vector#(2,FIFO#(Bit#(15))) axiSlaveReadAddrFifos <- replicateM(mkPipelineFIFO);
    Vector#(2,FIFO#(Bit#(32))) axiSlaveWriteDataFifos <- replicateM(mkPipelineFIFO);
    Vector#(2,FIFO#(Bit#(32))) axiSlaveReadDataFifos <- replicateM(mkPipelineFIFO);

    Reg#(Bit#(1)) axiSlaveRS <- mkReg(0);
    Reg#(Bit#(1)) axiSlaveWS <- mkReg(0);

    let axiSlaveWriteAddrFifo = axiSlaveWriteAddrFifos[%(slaveFifoSelExposed)s];
    let axiSlaveReadAddrFifo  = axiSlaveReadAddrFifos[%(slaveFifoSelExposed)s];
    let axiSlaveWriteDataFifo = axiSlaveWriteDataFifos[%(slaveFifoSelExposed)s];
    let axiSlaveReadDataFifo  = axiSlaveReadDataFifos[%(slaveFifoSelExposed)s];

    rule axiSlaveReadAddressGenerator if (axiSlaveReadBurstCountReg != 0);
         axiSlaveReadAddrFifos[axiSlaveRS].enq(truncate(axiSlaveReadAddrReg));
         axiSlaveReadAddrReg <= axiSlaveReadAddrReg + 4;
         axiSlaveReadBurstCountReg <= axiSlaveReadBurstCountReg - 1;
         axiSlaveReadLastFifo.enq(axiSlaveReadBurstCountReg == 1 ? 1 : 0);
         axiSlaveReadIdFifo.enq(axiSlaveReadIdReg);
    endrule 
'''

proxyCtrlTemplate='''
    // indication-specific state
    Reg#(Bit#(32)) responseFiredCntReg <- mkReg(0);
    Reg#(Bit#(32)) underflowReadCountReg <- mkReg(0);
    Reg#(Bit#(32)) outOfRangeReadCountReg <- mkReg(0);
    Reg#(Bit#(32)) outOfRangeWriteCount <- mkReg(0);
    Vector#(%(indicationChannelCount)s, PulseWire) responseFiredWires <- replicateM(mkPulseWire);
    ReadyQueue#(%(indicationChannelCount)s, Bit#(TAdd#(iccsz,1)), Bit#(TAdd#(iccsz,1))) rq <- mkFirstReadyQueue();
    
    Reg#(Bool) interruptEnableReg <- mkReg(False);
    let       interruptStatus = tpl_2(rq.maxPriorityRequest) > 0;
    function Bit#(32) read_wire_cvt (PulseWire a) = a._read ? 32'b1 : 32'b0;
    function Bit#(32) my_add(Bit#(32) a, Bit#(32) b) = a+b;

    // count the number of times indication methods are invoked
    rule increment_responseFiredCntReg;
        responseFiredCntReg <= responseFiredCntReg + fold(my_add, map(read_wire_cvt, responseFiredWires));
    endrule
    
    rule writeCtrlReg if (axiSlaveWriteAddrFifo.first[14] == 1);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
	let addr = axiSlaveWriteAddrFifo.first[13:0];
	let v = axiSlaveWriteDataFifo.first;
	if (addr == 14'h000)
	    noAction;
	if (addr == 14'h004)
	    interruptEnableReg <= v[0] == 1'd1;
    endrule
    rule writeIndicatorFifo if (axiSlaveWriteAddrFifo.first[14] == 0);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        outOfRangeWriteCount <= outOfRangeWriteCount + 1;
    endrule

    rule readCtrlReg if (axiSlaveReadAddrFifo.first[14] == 1);

        axiSlaveReadAddrFifo.deq;
	let addr = axiSlaveReadAddrFifo.first[13:0];

        //$display(\"proxy readCtrlReg %%h\", addr);

	Bit#(32) v = 32'h05a05a0;
	if (addr == 14'h000)
	    v = interruptStatus ? 32'd1 : 32'd0;
	if (addr == 14'h004)
	    v = interruptEnableReg ? 32'd1 : 32'd0;
	if (addr == 14'h008)
	    v = %(indicationChannelCount)s;
	if (addr == 14'h00C)
	    v = underflowReadCountReg;
	if (addr == 14'h010)
	    v = outOfRangeReadCountReg;
	if (addr == 14'h014)
	    v = outOfRangeWriteCount;
        if (addr == 14'h018) begin
            if (tpl_2(rq.maxPriorityRequest) > 0) 
              v = extend(tpl_1(rq.maxPriorityRequest))+1;
            else 
              v = 0;
        end
%(readAxiState)s
        axiSlaveReadDataFifo.enq(v);
    endrule

%(indicationMethodRules)s

    rule outOfRangeRead if (axiSlaveReadAddrFifo.first[14] == 0 && 
                            axiSlaveReadAddrFifo.first[13:8] >= %(indicationChannelCount)s);
        axiSlaveReadAddrFifo.deq;
        axiSlaveReadDataFifo.enq(0);
        outOfRangeReadCountReg <= outOfRangeReadCountReg+1;
    endrule

%(startIndicationMethods)s
%(indicationMethods)s
%(endIndicationMethods)s
'''


requestRuleTemplate='''
    FromBit#(32,%(MethodName)s$Request) %(methodName)s$requestFifo <- mkFromBit();
    rule axiSlaveWrite$%(methodName)s if (axiSlaveWriteAddrFifo.first[14] == 0 && axiSlaveWriteAddrFifo.first[13:8] == %(methodName)s$Offset);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        %(methodName)s$requestFifo.enq(axiSlaveWriteDataFifo.first);
    endrule
    (* descending_urgency = "handle$%(methodName)s$request, handle$%(methodName)s$requestFailure" *)
    rule handle$%(methodName)s$request if (putEnable);
        let request = %(methodName)s$requestFifo.first;
        %(methodName)s$requestFifo.deq;
        %(invokeMethod)s
        requestFiredPulse.send();
    endrule
    rule handle$%(methodName)s$requestFailure;
        %(putFailed)s
        %(methodName)s$requestFifo.deq;
        $display("%(methodName)s$requestFailure");
    endrule
'''

indicationRuleTemplate='''
    ToBit#(32,%(MethodName)s$Response) %(methodName)s$responseFifo <- mkToBit();
    rule %(methodName)s$read if (axiSlaveReadAddrFifo.first[14] == 0 && 
                                         axiSlaveReadAddrFifo.first[13:8] == %(methodName)s$Offset);
        axiSlaveReadAddrFifo.deq;
        let v = 32'hbad0dada;
        if (%(methodName)s$responseFifo.notEmpty) begin
            %(methodName)s$responseFifo.deq;
            v = %(methodName)s$responseFifo.first;
        end
        else begin
            underflowReadCountReg <= underflowReadCountReg + 1;
            $display("underflow");
        end
        axiSlaveReadDataFifo.enq(v);
    endrule
    rule %(methodName)s$ReadyBit;
        rq.readyBits[%(methodName)s$Offset] <= %(methodName)s$responseFifo.notEmpty;
    endrule
'''

indicationMethodDeclTemplate='''
    method Action %(methodName)s(%(formals)s);'''

indicationMethodTemplate='''
    method Action %(methodName)s(%(formals)s);
        %(methodName)s$responseFifo.enq(%(MethodName)s$Response {%(structElements)s});
        responseFiredWires[%(channelNumber)s].send();
        //$display(\"indicationMethod \'%(methodName)s\' invoked\");
    endmethod'''


mkHiddenWrapperInterfaceTemplate='''
// hidden wrapper implementation
module %(moduleContext)s mk%(Dut)s#(FIFO#(Bit#(15)) axiSlaveWriteAddrFifo,
                            FIFO#(Bit#(15)) axiSlaveReadAddrFifo,
                            FIFO#(Bit#(32)) axiSlaveWriteDataFifo,
                            FIFO#(Bit#(32)) axiSlaveReadDataFifo)(%(Dut)s)
    provisos (Log#(%(indicationChannelCount)s,iccsz));
%(wrapperCtrl)s
endmodule
'''

mkExposedWrapperInterfaceTemplate='''
// exposed wrapper implementation
module mk%(Dut)s#(idType id, %(Ifc)s ifc)(%(Dut)s)
    provisos (Log#(%(indicationChannelCount)s,iccsz),
              Bits#(idType, __a), 
              Add#(a__, __a, 32));
%(axiState)s
    // instantiate hidden proxy to report put failures
    %(hiddenProxy)s p <- mk%(hiddenProxy)s(axiSlaveWriteAddrFifos[%(slaveFifoSelHidden)s],
                                           axiSlaveReadAddrFifos[%(slaveFifoSelHidden)s],
                                           axiSlaveWriteDataFifos[%(slaveFifoSelHidden)s],
                                           axiSlaveReadDataFifos[%(slaveFifoSelHidden)s]);
%(wrapperCtrl)s
%(portalIfc)s
endmodule
'''

mkHiddenProxyInterfaceTemplate='''
// hidden proxy implementation
module %(moduleContext)s mk%(Dut)s#(FIFO#(Bit#(15)) axiSlaveWriteAddrFifo,
                            FIFO#(Bit#(15)) axiSlaveReadAddrFifo,
                            FIFO#(Bit#(32)) axiSlaveWriteDataFifo,
                            FIFO#(Bit#(32)) axiSlaveReadDataFifo)(%(Dut)s)
    provisos (Log#(%(indicationChannelCount)s,iccsz));
%(proxyCtrl)s
%(portalIfcInterrupt)s
endmodule
'''

mkExposedProxyInterfaceTemplate='''
// exposed proxy implementation
module %(moduleContext)s mk%(Dut)s#(idType id) (%(Dut)s) 
    provisos (Log#(%(indicationChannelCount)s,iccsz),
              Bits#(idType, __a), 
              Add#(a__, __a, 32));
%(axiState)s
    // instantiate hidden wrapper to receive failure notifications
    %(hiddenWrapper)s p <- mk%(hiddenWrapper)s(axiSlaveWriteAddrFifos[%(slaveFifoSelHidden)s],
                                           axiSlaveReadAddrFifos[%(slaveFifoSelHidden)s],
                                           axiSlaveWriteDataFifos[%(slaveFifoSelHidden)s],
                                           axiSlaveReadDataFifos[%(slaveFifoSelHidden)s]);
%(proxyCtrl)s
%(portalIfc)s
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
        if (self.name == 'Int'):
            return self.params[0].numeric()
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
            'requestFailureRuleNames': "" if len(methodNames) == 0 else '(* descending_urgency = "'+', '.join(['handle$%s$requestFailure' % n for n in methodNames])+'"*)',
            'channelCount': self.channelCount,
            'writeChannelCount': self.channelCount,
            'Ifc': self.name,
            'hiddenProxy' : "%sStatus" % name,
            'moduleContext': '',

            'responseElements': ''.join(responseElements),
            'indicationMethodRules': ''.join(indicationMethodRules),
            'indicationMethods': ''.join(indicationMethods),
            'indicationMethodDecls' :''.join(indicationMethodDecls),
            'indicationChannelCount': self.channelCount,
            'indicationInterfaces': ''.join(indicationTemplate % { 'Indication': name }) if not self.hasSource else '',
            'hiddenWrapper' : "%sStatus" % name,
            'startIndicationMethods' : '' if not expose else '    interface %s ifc;' % self.name,
            'endIndicationMethods' : '' if not expose else '    endinterface',
            'slaveFifoSelExposed' : '1' if proxy else '0',
            'slaveFifoSelHidden'  : '0' if proxy else '1',
            }

        substs['readAxiState'] = '' if not expose else readAxiStateTemplate % substs
        substs['portalIfcInterrupt'] = 'interface ReadOnly interrupt = p.interrupt;' if not proxy else proxyInterruptImplTemplate
        substs['ifcType'] = 'truncate(128\'h%s)' % m.hexdigest()
        substs['axiState'] = axiStateTemplate % substs
        substs['portalIfc'] = portalIfcTemplate % substs
        substs['wrapperCtrl'] = wrapperCtrlTemplate % substs
        substs['proxyCtrl'] = proxyCtrlTemplate % substs
        return substs

    def emitBsvWrapper(self,f,suffix,expose):
        subs = self.substs(suffix,expose,False)
        if expose:
            #print "exposed wrapper: ", subs['dut']
            f.write(exposedWrapperInterfaceTemplate % subs)
            f.write(mkExposedWrapperInterfaceTemplate % subs)
        else:
            #print "hidden wrapper: ", subs['dut']
            f.write(hiddenWrapperInterfaceTemplate % subs)
            f.write(mkHiddenWrapperInterfaceTemplate % subs)

    def emitBsvProxy(self,f,suffix,expose):
        subs = self.substs(suffix,expose,True)
        if expose:
            #print " exposed proxy: ", subs['dut']
            f.write(exposedProxyInterfaceTemplate % subs)
            f.write(mkExposedProxyInterfaceTemplate % subs)
        else:
            #print "   hidden proxy: ", subs['dut']
            f.write(hiddenProxyInterfaceTemplate % subs)
            f.write(mkHiddenProxyInterfaceTemplate % subs)

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
                    methodRuleNames.append('axiSlaveWrite$%s' % m.name)
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
                    methodRuleNames.append("%s$axiSlaveRead" % m.name)
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
