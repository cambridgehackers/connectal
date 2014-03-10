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
import Adapter::*;
import AxiMasterSlave::*;
import Leds::*;
import Vector::*;
import SpecialFIFOs::*;
import PortalMemory::*;
import Portal::*;
import GetPutF::*;
%(extraImports)s

typedef struct {
    Bit#(1) select;
    Bit#(1) last;
    Bit#(12) id;
} ReadReqInfo deriving (Bits);

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
        // $display(\"wrapper readCtrlReg %%h\", addr);
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
    interface Axi3Slave ctrl;
        interface Put req_aw;
            method Action put(Axi3WriteRequest#(32,12) req);
                 req_aw_fifo.enq(req);
            endmethod
        endinterface: req_aw
        interface Put resp_write;
            method Action put(Axi3WriteData#(32,12) wdata);
                let ws = axiSlaveWS;
                let wbc = axiSlaveWriteBurstCountReg;
                let wa = axiSlaveWriteAddrReg;
                let wid = axiSlaveWriteIdReg;
                if (axiSlaveWriteBurstCountReg == 0) begin
                    let req = req_aw_fifo.first;
                    ws = req.address[15];
                    wbc = req.len + 1;
                    wa = truncate(req.address);
	   	    wid = req.id;
                    req_aw_fifo.deq;
                end
                let addr = wa;
                axiSlaveWriteAddrReg <= wa + 4;
                axiSlaveWriteBurstCountReg <= wbc - 1;

                axiSlaveWriteAddrFifos[ws].enq(wa[14:0]);
                axiSlaveWriteDataFifos[ws].enq(wdata.data);

                if (wdata.last == 1'b1)
                    axiSlaveBrespFifo.enq(Axi3WriteResponse { resp: 0, id: wdata.id });

                axiSlaveWS <= ws;
                axiSlaveWriteIdReg <= wid;
            endmethod
        endinterface
        interface GetF resp_b;
            method ActionValue#(Axi3WriteResponse#(12)) get();
                axiSlaveBrespFifo.deq;
                return axiSlaveBrespFifo.first;
            endmethod
            method Bool notEmpty();
                return axiSlaveBrespFifo.notEmpty;
            endmethod
        endinterface
        interface Put req_ar;
            method Action put(Axi3ReadRequest#(32,12) req);
                req_ar_fifo.enq(req);
            endmethod
        endinterface
        interface GetF resp_read;
            method ActionValue#(Axi3ReadResponse#(32,12)) get();
                let info = axiSlaveReadReqInfoFifo.first();
                axiSlaveReadReqInfoFifo.deq();
                let v = axiSlaveReadDataFifos[info.select].first;
                axiSlaveReadDataFifos[info.select].deq;
                return Axi3ReadResponse { data: v, last: info.last, id: info.id, resp: 0 };
            endmethod
            method Bool notEmpty();
                Bool rv = False;
                if(axiSlaveReadReqInfoFifo.notEmpty) begin
                    let info = axiSlaveReadReqInfoFifo.first();
                    rv = axiSlaveReadDataFifos[info.select].notEmpty();
                end
                return rv;
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
	    v = zeroExtend(axiSlaveReadAddrReg);
	if (addr == 14'h020)
	    v = zeroExtend(axiSlaveWriteAddrReg);
	if (addr == 14'h024)
	    v = zeroExtend(axiSlaveReadIdReg);
	if (addr == 14'h028)
	    v = zeroExtend(axiSlaveWriteIdReg);
	if (addr == 14'h02C)
	    v = zeroExtend(axiSlaveReadBurstCountReg);
	if (addr == 14'h030)
	    v = zeroExtend(axiSlaveWriteBurstCountReg);

'''

axiStateTemplate='''
    // state used to implement Axi Slave interface
    Reg#(Bit#(15)) axiSlaveReadAddrReg <- mkReg(0);
    Reg#(Bit#(15)) axiSlaveWriteAddrReg <- mkReg(0);
    Reg#(Bit#(12)) axiSlaveReadIdReg <- mkReg(0);
    Reg#(Bit#(12)) axiSlaveWriteIdReg <- mkReg(0);
    FIFOF#(ReadReqInfo) axiSlaveReadReqInfoFifo <- mkFIFOF;
    Reg#(Bit#(4)) axiSlaveReadBurstCountReg <- mkReg(0);
    Reg#(Bit#(4)) axiSlaveWriteBurstCountReg <- mkReg(0);
    FIFOF#(Axi3WriteResponse#(12)) axiSlaveBrespFifo <- mkFIFOF();

    Vector#(2,FIFO#(Bit#(15))) axiSlaveWriteAddrFifos <- replicateM(mkFIFO);
    Vector#(2,FIFO#(Bit#(15))) axiSlaveReadAddrFifos <- replicateM(mkFIFO);
    Vector#(2,FIFO#(Bit#(32))) axiSlaveWriteDataFifos <- replicateM(mkFIFO);
    Vector#(2,FIFOF#(Bit#(32))) axiSlaveReadDataFifos <- replicateM(mkFIFOF);

    Reg#(Bit#(1)) axiSlaveRS <- mkReg(0);
    Reg#(Bit#(1)) axiSlaveWS <- mkReg(0);

    FIFO#(Axi3ReadRequest#(32,12))  req_ar_fifo <- mkSizedFIFO(1);
    FIFO#(Axi3WriteRequest#(32,12)) req_aw_fifo <- mkSizedFIFO(1);

    let axiSlaveWriteAddrFifo = axiSlaveWriteAddrFifos[%(slaveFifoSelExposed)s];
    let axiSlaveReadAddrFifo  = axiSlaveReadAddrFifos[%(slaveFifoSelExposed)s];
    let axiSlaveWriteDataFifo = axiSlaveWriteDataFifos[%(slaveFifoSelExposed)s];
    let axiSlaveReadDataFifo  = axiSlaveReadDataFifos[%(slaveFifoSelExposed)s];

    rule axiSlaveReadAddressGenerator;
         if (axiSlaveReadBurstCountReg == 0) begin
             let req = req_ar_fifo.first;
             axiSlaveRS <= req.address[15];
             axiSlaveReadBurstCountReg <= req.len + 1;
             axiSlaveReadAddrReg <= truncate(req.address);
	     axiSlaveReadIdReg <= req.id;
             req_ar_fifo.deq;
         end
         else begin
             axiSlaveReadAddrFifos[axiSlaveRS].enq(truncate(axiSlaveReadAddrReg));
             axiSlaveReadAddrReg <= axiSlaveReadAddrReg + 4;
             axiSlaveReadBurstCountReg <= axiSlaveReadBurstCountReg - 1;
             axiSlaveReadReqInfoFifo.enq(ReadReqInfo { select: axiSlaveRS, last: axiSlaveReadBurstCountReg == 1 ? 1 : 0, id: axiSlaveReadIdReg });
         end
    endrule 
'''

proxyCtrlTemplate='''
    // indication-specific state
    Reg#(Bit#(32)) responseFiredCntReg <- mkReg(0);
    Reg#(Bit#(32)) underflowReadCountReg <- mkReg(0);
    Reg#(Bit#(32)) outOfRangeReadCountReg <- mkReg(0);
    Reg#(Bit#(32)) outOfRangeWriteCount <- mkReg(0);
    Vector#(%(indicationChannelCount)s, PulseWire) responseFiredWires <- replicateM(mkPulseWire);
    Vector#(%(indicationChannelCount)s, Bool) readyBits = replicate(False);

    Reg#(Bool) interruptEnableReg <- mkReg(False);
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

%(indicationMethodRules)s

    Bool      interruptStatus = False;
    Bit#(32)  readyChannel = -1;
    for (Integer i = 0; i < %(indicationChannelCount)s; i = i + 1) begin
        if (readyBits[i]) begin
           interruptStatus = True;
           readyChannel = fromInteger(i);
        end
    end

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
            if (interruptStatus)
              v = readyChannel+1;
            else 
              v = 0;
        end
%(readAxiState)s
        axiSlaveReadDataFifo.enq(v);
    endrule

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
    readyBits[%(methodName)s$Offset] = %(methodName)s$responseFifo.notEmpty;
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
                            FIFOF#(Bit#(32)) axiSlaveReadDataFifo)(%(Dut)s);
%(wrapperCtrl)s
endmodule
'''

mkExposedWrapperInterfaceTemplate='''
// exposed wrapper implementation
module mk%(Dut)s#(idType id, %(Ifc)s ifc)(%(Dut)s)
    provisos (Bits#(idType, __a), 
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
                            FIFOF#(Bit#(32)) axiSlaveReadDataFifo)(%(Dut)s);
%(proxyCtrl)s
%(portalIfcInterrupt)s
endmodule
'''

mkExposedProxyInterfaceTemplate='''
(* synthesize *)
module %(moduleContext)s mk%(Dut)sSynth#(Bit#(32) id) (%(Dut)s);
%(axiState)s
    // instantiate hidden wrapper to receive failure notifications
    %(hiddenWrapper)s p <- mk%(hiddenWrapper)s(axiSlaveWriteAddrFifos[%(slaveFifoSelHidden)s],
                                           axiSlaveReadAddrFifos[%(slaveFifoSelHidden)s],
                                           axiSlaveWriteDataFifos[%(slaveFifoSelHidden)s],
                                           axiSlaveReadDataFifos[%(slaveFifoSelHidden)s]);
%(proxyCtrl)s
%(portalIfc)s
endmodule

// exposed proxy implementation
module %(moduleContext)s mk%(Dut)s#(idType id) (%(Dut)s) 
    provisos (Bits#(idType, __a), 
              Add#(a__, __a, 32));
    let rv <- mk%(Dut)sSynth(extend(pack(id)));
    return rv;
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
