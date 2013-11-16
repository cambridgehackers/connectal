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
import Zynq::*;
import Vector::*;
import SpecialFIFOs::*;
import AxiDMA::*;
import XbsvReadyQueue::*;
import PortalMemory::*;
%(extraImports)s

'''

exposedInterfaces = ['HDMI', 'LEDS', 'ImageonVita', 'ImageonTopPins', 'ImageonSerdesPins', 'FmcImageonInterface', 'SpiPins', 'ImageonPins', 'TlpTrace']


bsimTopTemplate='''
import StmtFSM::*;
import AxiMasterSlave::*;
import FIFO::*;
import SpecialFIFOs::*;
import %(Base)sWrapper::*;


import "BDPI" function Action      initPortal(Bit#(32) d);

import "BDPI" function Bool                    writeReq();
import "BDPI" function ActionValue#(Bit#(32)) writeAddr();
import "BDPI" function ActionValue#(Bit#(32)) writeData();

import "BDPI" function Bool                     readReq();
import "BDPI" function ActionValue#(Bit#(32))  readAddr();
import "BDPI" function Action        readData(Bit#(32) d);


module mkBsimTop();
    %(Base)sWrapper dut <- mk%(Base)sWrapper;
    let wf <- mkPipelineFIFO;
    let init_seq = (action 
                        %(initBsimPortals)s
                    endaction);
    let init_fsm <- mkOnce(init_seq);
    rule init_rule;
        init_fsm.start;
    endrule
    rule wrReq (writeReq());
        let wa <- writeAddr;
        let wd <- writeData;
        dut.ctrl.write.writeAddr(wa,0,0,0,0,0,0);
        wf.enq(wd);
    endrule
    rule wrData;
        wf.deq;
        dut.ctrl.write.writeData(wf.first,0,0,0);
    endrule
    rule rdReq (readReq());
        let ra <- readAddr;
        dut.ctrl.read.readAddr(ra,0,0,0,0,0,0);
    endrule
    rule rdResp;
        let rd <- dut.ctrl.read.readData;
        readData(rd);
    endrule
endmodule
'''

pcieTopTemplate='''
import Vector            :: *;
import Clocks            :: *;
import Connectable       :: *;
import Assert            :: *;
import Xilinx            :: *;
import XilinxPCIE        :: *;
import Kintex7PcieBridge :: *;
import Virtex7PcieBridge :: *;
import PcieToAxiBridge   :: *;
import %(Dut)sWrapper       :: *;

(* synthesize, no_default_clock, no_default_reset *)
module mk%(Dut)sPcieTop #(Clock pci_sys_clk_p, Clock pci_sys_clk_n,
                          Clock sys_clk_p,     Clock sys_clk_n,
                          Reset pci_sys_reset_n)
                         (%(fpga_interface)s);

   let contentId = %(contentid)s;

`ifdef Kintex7
   K7PcieBridgeIfc#(8) x7pcie <- mkK7PcieBridge( pci_sys_clk_p, pci_sys_clk_n, sys_clk_p, sys_clk_n, pci_sys_reset_n,
                                                 contentId );
`elsif Virtex7
   V7PcieBridgeIfc#(8) x7pcie <- mkV7PcieBridge( pci_sys_clk_p, pci_sys_clk_n, sys_clk_p, sys_clk_n, pci_sys_reset_n,
                                                 contentId );
`else
   staticAssert(False, "Define preprocessor macro Virtex7 or Kintex7 to configure platform.");
`endif

   
   Reg#(Bool) interruptRequested <- mkReg(False, clocked_by x7pcie.clock125, reset_by x7pcie.reset125);
   %(Dut)sWrapper %(dut)sWrapper <- mk%(Dut)sWrapper(clocked_by x7pcie.clock125, reset_by x7pcie.reset125);
   mkConnection(x7pcie.portal0, %(dut)sWrapper.ctrl, clocked_by x7pcie.clock125, reset_by x7pcie.reset125);
   %(tlpTraceConnection)s
%(axiMasterConnections)s
   rule numPortals;
       x7pcie.numPortals <= %(dut)sWrapper.numPortals;
   endrule
   
   function Bool my_read(ReadOnly#(Bool) r); return r._read; endfunction
   function Bool my_or (Bool a, Bool b); return a || b; endfunction

   rule requestInterrupt;
      Bool interrupt = fold(my_or, map(my_read, %(dut)sWrapper.interrupts));
      if (interrupt && !interruptRequested)
	 x7pcie.interrupt();
      interruptRequested <= interrupt;
   endrule

   interface pcie = x7pcie.pcie;
   //interface ddr3 = x7pcie.ddr3;
   method leds = zeroExtend({  pack(x7pcie.isCalibrated)
			     , pack(True)
			     , pack(False)
			     , pack(x7pcie.isLinkUp)
			     });

endmodule: mk%(Dut)sPcieTop
'''

axiMasterConnectionTemplate='''
   AxiSlaveEngine#(%(buswidth)s,%(buswidthbytes)s) axiSlaveEngine <- mkAxiSlaveEngine(x7pcie.pciId(), clocked_by x7pcie.clock125, reset_by x7pcie.reset125);
   mkConnection(tpl_1(x7pcie.slave), tpl_2(axiSlaveEngine.tlps), clocked_by x7pcie.clock125, reset_by x7pcie.reset125);
   mkConnection(tpl_1(axiSlaveEngine.tlps), tpl_2(x7pcie.slave), clocked_by x7pcie.clock125, reset_by x7pcie.reset125);
   mkConnection(%(dut)sWrapper.%(busname)s, axiSlaveEngine.slave%(axiversion)s, clocked_by x7pcie.clock125, reset_by x7pcie.reset125);
'''
tlpTraceConnectionTemplate='''
   mkConnection(%(dut)sWrapper.%(busname)s.tlp, x7pcie.trace);
'''


topInterfaceTemplate='''
interface %(Base)sWrapper;
    interface Axi3Slave#(32,32,4,12) ctrl;
    interface Vector#(%(numPortals)s,ReadOnly#(Bool)) interrupts;
%(axiSlaveDeclarations)s
%(axiMasterDeclarations)s
%(exposedInterfaceDeclarations)s
    interface ReadOnly#(Bit#(4)) numPortals;
endinterface
'''

requestWrapperInterfaceTemplate='''
%(requestElements)s
interface %(Dut)sWrapper;
%(axiSlaveDeclarations)s
%(axiMasterDeclarations)s
endinterface
'''

requestStructTemplate='''
typedef struct {
%(paramStructDeclarations)s
} %(MethodName)s$Request deriving (Bits);
Bit#(6) %(methodName)s$Offset = %(channelNumber)s;
'''

indicationWrapperInterfaceTemplate='''
%(responseElements)s
interface RequestWrapperCommFIFOs;
    interface FIFO#(Bit#(15)) axiSlaveWriteAddrFifo;
    interface FIFO#(Bit#(15)) axiSlaveReadAddrFifo;
    interface FIFO#(Bit#(32)) axiSlaveWriteDataFifo;
    interface FIFO#(Bit#(32)) axiSlaveReadDataFifo;
endinterface

interface %(Dut)sWrapper;
    interface Axi3Slave#(32,32,4,12) ctrl;
    interface ReadOnly#(Bool) putEnable;
    interface ReadOnly#(Bool) interrupt;
    interface %(Dut)s indication;
    interface RequestWrapperCommFIFOs rwCommFifos;%(indicationMethodDeclsAug)s
endinterface
'''

responseStructTemplate='''
typedef struct {
%(paramStructDeclarations)s
} %(MethodName)s$Response deriving (Bits);
Bit#(6) %(methodName)s$Offset = %(channelNumber)s;
'''

mkIndicationWrapperTemplate='''

%(mutexRuleList)s
module mk%(Dut)sWrapper(%(Dut)sWrapper) provisos (Log#(%(indicationChannelCount)s,iccsz));

    // indication-specific state
    Reg#(Bit#(32)) responseFiredCntReg <- mkReg(0);
    Vector#(%(indicationChannelCount)s, PulseWire) responseFiredWires <- replicateM(mkPulseWire);
    Reg#(Bit#(32)) underflowReadCountReg <- mkReg(0);
    Reg#(Bit#(32)) outOfRangeReadCountReg <- mkReg(0);
    Reg#(Bit#(32)) outOfRangeWriteCount <- mkReg(0);
    ReadyQueue#(%(indicationChannelCount)s, Bit#(iccsz), Bit#(iccsz)) rq <- mkFirstReadyQueue();
    
    function Bool my_or(Bool a, Bool b) = a || b;
    function Bool read_wire (PulseWire a) = a._read;    
    // this is here to disable the warning that the put failed rule can never fire
    Reg#(Bool) putEnableReg <- mkReg(True);
    Reg#(Bool) interruptEnableReg <- mkReg(False);
    let       interruptStatus = tpl_2(rq.maxPriorityRequest) != 0;
    function Bit#(32) read_wire_cvt (PulseWire a) = a._read ? 32'b1 : 32'b0;
    function Bit#(32) my_add(Bit#(32) a, Bit#(32) b) = a+b;

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
    FIFO#(Bit#(2)) axiSlaveBrespFifo <- mkFIFO();
    FIFO#(Bit#(12)) axiSlaveBidFifo <- mkFIFO();

    Vector#(2,FIFO#(Bit#(15))) axiSlaveWriteAddrFifos <- replicateM(mkPipelineFIFO);
    Vector#(2,FIFO#(Bit#(15))) axiSlaveReadAddrFifos <- replicateM(mkPipelineFIFO);
    Vector#(2,FIFO#(Bit#(32))) axiSlaveWriteDataFifos <- replicateM(mkPipelineFIFO);
    Vector#(2,FIFO#(Bit#(32))) axiSlaveReadDataFifos <- replicateM(mkPipelineFIFO);

    Reg#(Bit#(1)) axiSlaveRS <- mkReg(0);
    Reg#(Bit#(1)) axiSlaveWS <- mkReg(0);

    let axiSlaveWriteAddrFifo = axiSlaveWriteAddrFifos[1];
    let axiSlaveReadAddrFifo  = axiSlaveReadAddrFifos[1];
    let axiSlaveWriteDataFifo = axiSlaveWriteDataFifos[1];
    let axiSlaveReadDataFifo  = axiSlaveReadDataFifos[1];

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
	    noAction; // interruptStatus is read-only
	if (addr == 14'h004)
	    interruptEnableReg <= v[0] == 1'd1;
	if (addr == 14'h008)
	    putEnableReg <= v[0] == 1'd1;
    endrule
    rule writeIndicatorFifo if (axiSlaveWriteAddrFifo.first[14] == 0);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        outOfRangeWriteCount <= outOfRangeWriteCount + 1;
    endrule

    rule readCtrlReg if (axiSlaveReadAddrFifo.first[14] == 1);

        axiSlaveReadAddrFifo.deq;
	let addr = axiSlaveReadAddrFifo.first[13:0];

	Bit#(32) v = 32'h05a05a0;
	if (addr == 14'h000)
	    v = interruptStatus ? 32'd1 : 32'd0;
	if (addr == 14'h004)
	    v = interruptEnableReg ? 32'd1 : 32'd0;
	if (addr == 14'h008)
	    v = responseFiredCntReg;
	if (addr == 14'h00C)
	    v = 0; // unused
	if (addr == 14'h010)
	    v = (32'h68470000 | extend(axiSlaveReadBurstCountReg));
	if (addr == 14'h014)
	    v = putWordCount;
	if (addr == 14'h018)
	    v = getWordCount;
        if (addr == 14'h01C)
	    v = outOfRangeReadCountReg;
        if (addr == 14'h020) begin
            if (tpl_2(rq.maxPriorityRequest) > 0) 
              v = extend(tpl_1(rq.maxPriorityRequest))+1;
            else 
              v = 0;
        end
	if (addr == 14'h034)
	    v = outOfRangeWriteCount;
	if (addr == 14'h038)
	    v = underflowReadCountReg;
        axiSlaveReadDataFifo.enq(v);
    endrule

%(indicationMethodRules)s

    rule outOfRangeRead if (axiSlaveReadAddrFifo.first[14] == 0 && 
                            axiSlaveReadAddrFifo.first[13:8] >= %(indicationChannelCount)s);
        axiSlaveReadAddrFifo.deq;
        axiSlaveReadDataFifo.enq(0);
        outOfRangeReadCountReg <= outOfRangeReadCountReg+1;
    endrule


    rule axiSlaveReadAddressGenerator if (axiSlaveReadBurstCountReg != 0);
        axiSlaveReadAddrFifos[axiSlaveRS].enq(truncate(axiSlaveReadAddrReg));
        axiSlaveReadAddrReg <= axiSlaveReadAddrReg + 4;
        axiSlaveReadBurstCountReg <= axiSlaveReadBurstCountReg - 1;
        axiSlaveReadLastFifo.enq(axiSlaveReadBurstCountReg == 1 ? 1 : 0);
        axiSlaveReadIdFifo.enq(axiSlaveReadIdReg);
    endrule

    interface RequestWrapperCommFIFOs rwCommFifos;
        interface FIFO axiSlaveWriteAddrFifo = axiSlaveWriteAddrFifos[0];
        interface FIFO axiSlaveReadAddrFifo  = axiSlaveReadAddrFifos[0];
        interface FIFO axiSlaveWriteDataFifo = axiSlaveWriteDataFifos[0];
        interface FIFO axiSlaveReadDataFifo  = axiSlaveReadDataFifos[0];
    endinterface

    interface Axi3Slave ctrl;
        interface Axi3SlaveWrite write;
            method Action writeAddr(Bit#(32) addr, Bit#(4) burstLen, Bit#(3) burstWidth,
                                    Bit#(2) burstType, Bit#(3) burstProt, Bit#(4) burstCache,
				    Bit#(12) awid)
                          if (axiSlaveWriteBurstCountReg == 0);
                 axiSlaveWS <= addr[15];
                 axiSlaveWriteBurstCountReg <= burstLen + 1;
                 axiSlaveWriteAddrReg <= truncate(addr);
		 axiSlaveWriteIdReg <= awid;
            endmethod
            method Action writeData(Bit#(32) v, Bit#(4) byteEnable, Bit#(1) last, Bit#(12) wid)
                          if (axiSlaveWriteBurstCountReg > 0);
                let addr = axiSlaveWriteAddrReg;
                axiSlaveWriteAddrReg <= axiSlaveWriteAddrReg + 4;
                axiSlaveWriteBurstCountReg <= axiSlaveWriteBurstCountReg - 1;

                axiSlaveWriteAddrFifos[axiSlaveWS].enq(axiSlaveWriteAddrReg[14:0]);
                axiSlaveWriteDataFifos[axiSlaveWS].enq(v);

                putWordCount <= putWordCount + 1;
                if (last == 1'b1)
                begin
                    axiSlaveBrespFifo.enq(0);
                    axiSlaveBidFifo.enq(wid);
                end
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
                 axiSlaveRS <= addr[15];
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

                let v = axiSlaveReadDataFifos[axiSlaveRS].first;
                axiSlaveReadDataFifos[axiSlaveRS].deq;
                axiSlaveReadLastFifo.deq;
                axiSlaveReadIdFifo.deq;

                getWordCount <= getWordCount + 1;
                return v;
            endmethod
        endinterface
    endinterface

    interface ReadOnly putEnable = regToReadOnly(putEnableReg);
    interface ReadOnly interrupt;
        method Bool _read();
            return (interruptEnableReg && interruptStatus);
        endmethod
    endinterface
    interface %(Dut)s indication;
%(indicationMethodsOrig)s
    endinterface
%(indicationMethodsAug)s

endmodule: mk%(Dut)sWrapper

'''

mkRequestWrapperTemplate='''


%(mutexRuleList)s
module mk%(Dut)sWrapper#(%(Dut)s %(dut)s, %(Indication)sWrapper iw)(%(Dut)sWrapper);

    // request-specific state
    Reg#(Bit#(32)) requestFiredCount <- mkReg(0);
    Reg#(Bit#(32)) overflowCount <- mkReg(0);
    Reg#(Bit#(32)) outOfRangeWriteCount <- mkReg(0);
    PulseWire requestFiredPulse <- mkPulseWireOR();

    let axiSlaveWriteAddrFifo = iw.rwCommFifos.axiSlaveWriteAddrFifo;
    let axiSlaveReadAddrFifo  = iw.rwCommFifos.axiSlaveReadAddrFifo;
    let axiSlaveWriteDataFifo = iw.rwCommFifos.axiSlaveWriteDataFifo;
    let axiSlaveReadDataFifo  = iw.rwCommFifos.axiSlaveReadDataFifo; 

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
    endrule

    rule readCtrlReg if (axiSlaveReadAddrFifo.first[14] == 1);
        axiSlaveReadAddrFifo.deq;
	let addr = axiSlaveReadAddrFifo.first[13:0];
	Bit#(32) v = 32'h05a05a0;
	if (addr == 14'h010)
	    v = requestFiredCount;
	if (addr == 14'h01C)
	    v = overflowCount;
	if (addr == 14'h034)
	    v = outOfRangeWriteCount;
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
%(axiMasterModules)s
%(axiSlaveImplementations)s
%(axiMasterImplementations)s
endmodule: mk%(Dut)sWrapper
'''

mkTopTemplate='''
module mk%(Base)sWrapper%(dut_hdmi_clock_param)s(%(Base)sWrapper);
    Reg#(Bit#(TLog#(%(numPortals)s))) axiSlaveWS <- mkReg(0);
    Reg#(Bit#(TLog#(%(numPortals)s))) axiSlaveRS <- mkReg(0); 
%(indicationWrappers)s
%(indicationIfc)s
    %(Dut)s %(dut)s <- mk%(Dut)s(%(dut_hdmi_clock_arg)s indication);
%(axiMasterModules)s
%(requestWrappers)s
    Vector#(%(numPortals)s,Axi3Slave#(32,32,4,12)) ctrls_v;
    Vector#(%(numPortals)s,ReadOnly#(Bool)) interrupts_v;
%(connectIndicationCtrls)s
%(connectIndicationInterrupts)s
    let ctrl_mux <- mkAxiSlaveMux(ctrls_v);
%(axiSlaveImplementations)s
%(axiMasterImplementations)s
%(exposedInterfaceImplementations)s
    interface ctrl = ctrl_mux;
    interface Vector interrupts = interrupts_v;
    interface ReadOnly numPortals;
        method Bit#(4) _read();
            return %(numPortals)s;
        endmethod
    endinterface
endmodule: mk%(Base)sWrapper
'''

# this used to sit in the requestRuleTemplate, but
# support for impCondOf in bsc is questionable (mdk)
#
# // let success = impCondOf(%(dut)s.%(methodName)s(%(paramsForCall)s));
# // if (success)
# // %(dut)s.%(methodName)s(%(paramsForCall)s);
# // else
# // indication$Aug.putFailed(%(ord)s);


requestRuleTemplate='''
    FromBit32#(%(MethodName)s$Request) %(methodName)s$requestFifo <- mkFromBit32();
    rule axiSlaveWrite$%(methodName)s if (axiSlaveWriteAddrFifo.first[14] == 0 && axiSlaveWriteAddrFifo.first[13:8] == %(methodName)s$Offset);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        %(methodName)s$requestFifo.enq(axiSlaveWriteDataFifo.first);
    endrule
    (* descending_urgency = "handle$%(methodName)s$request, handle$%(methodName)s$requestFailure" *)
    rule handle$%(methodName)s$request if (iw.putEnable); // iw.putEnable is always True
        let request = %(methodName)s$requestFifo.first;
        %(methodName)s$requestFifo.deq;
        %(dut)s.%(methodName)s(%(paramsForCall)s);
        requestFiredPulse.send();
    endrule
    rule handle$%(methodName)s$requestFailure;
        iw.putFailed(%(ord)s);
        %(methodName)s$requestFifo.deq;
        $display("%(methodName)s$requestFailure");
    endrule
'''

indicationRuleTemplate='''
    ToBit32#(%(MethodName)s$Response) %(methodName)s$responseFifo <- mkToBit32();
    rule %(methodName)s$axiSlaveRead if (axiSlaveReadAddrFifo.first[14] == 0 && 
                                         axiSlaveReadAddrFifo.first[13:8] == %(methodName)s$Offset);
        axiSlaveReadAddrFifo.deq;
        let v = 32'hbad0dada;
        if (%(methodName)s$responseFifo.notEmpty) begin
            %(methodName)s$responseFifo.deq;
            v = %(methodName)s$responseFifo.first;
        end
        else begin
            underflowReadCountReg <= underflowReadCountReg + 1;
        end
        axiSlaveReadDataFifo.enq(v);
    endrule
    rule %(methodName)s$ReadyBit;
        rq.readyBits[%(methodName)s$Offset] <= %(methodName)s$responseFifo.notEmpty();
    endrule
'''

indicationMethodDeclTemplate='''
    method Action %(methodName)s(%(formals)s);'''

indicationMethodTemplate='''
    method Action %(methodName)s(%(formals)s);
        %(methodName)s$responseFifo.enq(%(MethodName)s$Response {%(structElements)s});
        responseFiredWires[%(channelNumber)s].send();
    endmethod'''

projectBldTemplate='''
[DEFAULT]
bsc-compile-options:           	-aggressive-conditions -show-schedule -keep-inlined-boundaries -keep-fires -steps-warn-interval 1000000 -suppress-warnings G0046 -p +%(srcdirs)s:%(projectdir)s:%(projectdir)s/sources:%(projectdir)s/sources/%(base)s:../bsv
bsc-rts-options:               	-K1024M
bsc-link-options:              	-keep-fires -parallel-sim-link 8
bsv-source-directories:        	.
c++-header-aliases
verilog-simulator:             	cvc
log-directory:                 	.build/${BUILD_TARGET}/logs
c++-header-directory:          	.build/${BUILD_TARGET}/cpp
verilog-directory:             	.build/${BUILD_TARGET}/rtl
binary-directory:              	.build/${BUILD_TARGET}/obj
simulation-directory:          	.build/${BUILD_TARGET}/sim
info-directory:                	.build/${BUILD_TARGET}/info
exe-file:                      	.build/${BUILD_TARGET}/dut
scemi-parameters-file:         	.build/${BUILD_TARGET}/scemi.params
altera-directory:              	.build/${BUILD_TARGET}/fpga
xilinx-directory:              	.build/${BUILD_TARGET}/fpga
design-editor-output-directory: .build/${BUILD_TARGET}/rtl_mod
design-editor-output-params:    .build/${BUILD_TARGET}/scemi.params
workstation-project-file:       ${BUILD_TARGET}.bspec
design-editor-edit-params
design-editor-options:          --batch -bsvmodule mk%(Base)sPcieTop --blackbox 4
xilinx-use-planahead
xilinx-use-precompiled
scemi-tcp-port:                 4321
top-module:                     mk%(Base)sPcieTop

[mv_vlog_lib]
hide-target
run-shell-mv_vlog_lib-0:        mv ${PROJECT_ROOT}/directc_*.so .build/${BUILD_TARGET}/.
run-shell-mv_vlog_lib-1:        cd ${PROJECT_ROOT}/.build/${BUILD_TARGET} && ln -s ../../.build .build

[sw]
hide-target
run-shell-sw-0:                 cd sw && make clean && make
run-shell-sw-1:                 cd sw/bluenocd && make clean && make

[dut]
hide-target
verilog-define:                 BSV_TIMESCALE=1ns/100ps BSV_DUMP_LEVEL=0
scemi-type:                     TCP
create-workstation-project

[bsim_dut]
hide-target
extends-target:                 dut
top-file:                       ./Simulation.bsv
build-for:                      bluesim
bsv-define:                     BSIM SIMULATION

[kc705_dut]
hide-target
extends-target:                 dut
top-file:                       ./sources/%(base)s/%(Base)sPcieTop.bsv
build-for:                      kc705
scemi-clock-period:             30.0
bsc-compile-options:            -D Kintex7 -opt-undetermined-vals -unspecified-to 0 -remove-dollar -verilog-filter ${BLUESPECDIR}/bin/basicinout
scemi-type:                     PCIE_KINTEX7
sodimm-style:                   DDR3
bsv-define:                     DDR3

[vc707_dut]
hide-target
extends-target:                 dut
top-file:                       ./sources/%(base)s/%(Base)sPcieTop.bsv
build-for:                      vc707
scemi-clock-period:             30.0
bsc-compile-options:            -D Virtex7 -opt-undetermined-vals -unspecified-to 0 -remove-dollar -verilog-filter ${BLUESPECDIR}/bin/basicinout
scemi-type:                     PCIE_VIRTEX7
sodimm-style:                   DDR3
bsv-define:                     DDR3

[tb_tcl]
hide-target
scemi-tb
uses-tcl
build-for:                      c++
c++-options:                    -I${BLUESPECDIR}/SceMi/bsvxactors -I${BLUESPECDIR}/tcllib/include -g -O0
c++-files:                      ${PROJECT_ROOT}/sw/TclTb.cpp ${BLUESPECDIR}/tcllib/include/bsdebug_common.cpp
shared-lib:                     .build/${BUILD_TARGET}/libbsdebug.so

[kc705_tb]
hide-target
extends-target:                 tb_tcl
top-file:                       ./sources/%(base)s/%(Base)sPcieTop.bsv
post-targets:                   sw
scemi-type:                     PCIE_KINTEX7

[vc707_tb]
hide-target
extends-target:                 tb_tcl
top-file:                       ./sources/%(base)s/%(Base)sPcieTop.bsv
post-targets:                   sw
scemi-type:                     PCIE_VIRTEX7

################################################################################
[bluesim]
sub-targets:                    bsim_dut bsim_tb

[verilog]
sub-targets:                    vlog_dut vlog_tb

[kc705]
sub-targets:                    kc705_dut kc705_tb

[vc707]
sub-targets:                    vc707_dut vc707_tb
'''

def emitPreamble(f, files):
    extraImports = (['import %s::*;\n' % os.path.splitext(os.path.basename(fn))[0] for fn in files]
                   + ['import %s::*;\n' % i for i in syntax.globalimports ])
    #axiMasterDecarations = ['interface AxiMaster#(64,8) %s;' % axiMaster for axiMaster in axiMasterNames]
    #axiSlaveDecarations = ['interface AxiSlave#(32,4) %s;' % axiSlave for axiSlave in axiSlaveNames]
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
            return '%s#(%s)' % (self.name, self.params[0].numeric())
        else:
            return self.name
    def numBitsBSV(self):
        if (self.name == 'Bit'):
		return self.params[0].numeric()
	sdef = syntax.globalvars[self.name].tdtype
        if (sdef.type == 'Struct'):
            return sum([e.type.numBitsBSV() for e in sdef.elements])
        else:
            return sdef.numBitsBSV();

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

class InterfaceMixin:

    def emitBsimTop(self,f):
        substs = {
		'Base' : self.base ,
		'initBsimPortals' : ''.join(util.intersperse(('\n'+' '*24), ['initPortal(%d);' % j for j in range(len(self.ind.decls))]))
		}
        f.write(bsimTopTemplate % substs);

    def emitPcieTop(self,f,boardname,contentid):
        print self.collectInterfaceNames('^Axi[34]Client$', True)
        axiMasterConnections = [axiMasterConnectionTemplate % {'dut': util.decapitalize(self.base),
                                                               'busname': busname,
                                                               'buswidth': params[1].numeric(),
                                                               'buswidthbytes': params[1].numeric()/8,
                                                               'axiversion': 4 if (t == 'Axi4Client') else 3}
                                for (busname,t,params) in self.collectInterfaceNames('^Axi[34]Client$', True)]
        tlpTraceConnections = [tlpTraceConnectionTemplate % {'dut': util.decapitalize(self.base),
                                                             'busname': busname}
                               for (busname,t,params) in self.collectInterfaceNames('TlpTrace')]
        if boardname == 'kc705':
            fpga_interface = 'KC705_FPGA'
        else:
            fpga_interface = 'VC707_FPGA'
        substs = {
		'Dut' : self.base ,
		'dut' : util.decapitalize(self.base),
                'axiMasterConnections': '\n'.join(axiMasterConnections),
                'tlpTraceConnection': '\n'.join(tlpTraceConnections),
                'contentid' : contentid,
                'fpga_interface': fpga_interface
		}
        f.write(pcieTopTemplate % substs);

    def getClockArgNames(self, m):
        #print m
        #print m.params
        #print [ p.name for p in m.params if p.type.name == 'Clock']
        return [ p.name for p in m.params if p.type.name == 'Clock']

    def emitBsvImplementationRequestTop(self,f):
        axiMasters = self.collectInterfaceNames('Axi[34]Client', True)
        axiSlaves = self.collectInterfaceNames('AxiSlave')
        hdmiInterfaces = self.collectInterfaceNames('HDMI')
        ledInterfaces = self.collectInterfaceNames('LEDS')
        indicationWrappers = self.collectIndicationWrappers()
        connectIndicationCtrls = self.collectIndicationCtrls()
        connectIndicationInterrupts = self.collectIndicationInterrupts()
        requestWrappers = self.collectRequestWrappers()
        indicationIfc = self.generateIndicationIfc()
        dutName = util.decapitalize(self.name)
        methods = [d for d in self.decls if d.type == 'Method' and d.return_type.name == 'Action']
        buses = {}
        for busType in exposedInterfaces:
            collected = self.collectInterfaceNames(busType)
            buses[busType] = collected

        dut_clknames = self.getClockArgNames(syntax.globalvars['mk%s' % self.name])
        substs = {
            'dut': dutName,
            'Dut': util.capitalize(self.name),
            'base': util.decapitalize(self.base),
            'Base': self.base,
            'axiMasterDeclarations': '\n'.join(['    interface Axi%sMaster#(%s,%s,%s,%s) %s;' % (4 if t == 'Axi4Client' else 3,
                                                                                                 params[0].numeric(), params[1].numeric(), params[2].numeric(), params[3].numeric(),
                                                                                                 axiMaster)
                                                for (axiMaster,t,params) in axiMasters]),
            'axiSlaveDeclarations': '\n'.join(['    interface AxiSlave#(32,4) %s;' % axiSlave
                                               for (axiSlave,t,params) in axiSlaves]),
            'exposedInterfaceDeclarations':
                '\n'.join(['\n'.join(['    interface %s %s;' % (t, util.decapitalize(busname))
                                      for (busname,t,params) in buses[busType]])
                           for busType in exposedInterfaces]),
            'axiMasterModules': '\n'.join(['    Axi%(axiversion)sMaster#(%(addrWidth)s,%(busWidth)s,%(busWidthBytes)s,%(idWidth)s) %(axiMaster)sMaster <- mkAxi%(axiversion)sMaster(%(dutName)s.%(axiMaster)s);'
                                           % { 'axiversion': 4 if t == 'Axi4Client' else 3,
                                               'addrWidth': params[0].numeric(),
                                               'busWidth': params[1].numeric(),
                                               'busWidthBytes': params[2].numeric(),
                                               'idWidth': params[3].numeric(),
                                               'axiMaster': axiMaster,
                                               'dutName': dutName }
                                           for (axiMaster,t,params) in axiMasters]),
            'axiMasterImplementations': '\n'.join(['    interface Axi%sMaster %s = %sMaster;' % (4 if t == 'Axi4Client' else 3, axiMaster,axiMaster)
                                                   for (axiMaster,t,params) in axiMasters]),
            'dut_hdmi_clock_param': '#(%s)' % ', '.join(['Clock %s' % name for name in dut_clknames]) if len(dut_clknames) else '',
            'dut_hdmi_clock_arg': ' '.join(['%s,' % name for name in dut_clknames]),
            'axiSlaveImplementations': '\n'.join(['    interface AxiSlave %s = %s.%s;' % (axiSlave,dutName,axiSlave)
                                                  for (axiSlave,t,params) in axiSlaves]),
            'exposedInterfaceImplementations': '\n'.join(['\n'.join(['    interface %s %s = %s.%s;' % (t, busname, dutName, busname)
                                                                     for (busname,t,params) in buses[busType]])
                                                          for busType in exposedInterfaces]),
            'Indication' : self.ind.name,
            'numPortals' : self.numPortals,
            'indicationWrappers' : ''.join(indicationWrappers),
            'requestWrappers' : ''.join(requestWrappers),
            'indicationIfc' : indicationIfc,
            'connectIndicationCtrls' : connectIndicationCtrls,
            'connectIndicationInterrupts' : connectIndicationInterrupts
            }
        f.write(topInterfaceTemplate % substs)
        f.write(mkTopTemplate % substs)

    def writeTopBsv(self,f):
        assert(self.top and (not self.isIndication))
        self.emitBsvImplementationRequestTop(f)

    def writeBsimTop(self,fname):
        assert(self.top and (not self.isIndication))
	f = util.createDirAndOpen(fname, 'w')
        print 'Writing bsv file ', fname
	self.emitBsimTop(f);
	f.close()

    def writePcieTop(self,fname,boardname,contentid):
        assert(self.top and (not self.isIndication))
	f = util.createDirAndOpen(fname, 'w')
        print 'Writing bsv file ', fname
	self.emitPcieTop(f,boardname,contentid);
	f.close()

    def writeProjectBld(self,projectdirname,srcdirs=[]):
        assert(self.top and (not self.isIndication))
        fname = os.path.join(projectdirname, 'project.bld')
	f = util.createDirAndOpen(fname, 'w')
        print 'Writing project.bld file ', fname
        base = self.name.replace('Request','')                           
        subst = { 'Base': base, 'base': base.lower(), 'projectdir': os.path.abspath(projectdirname)}
        if srcdirs:
            subst['srcdirs'] = ':%s' % ':'.join([os.path.abspath(srcdir) for srcdir in srcdirs])
        else:
            subst['srcdirs'] = ''
        f.write(projectBldTemplate % subst)
	f.close()

    def collectIndicationInterrupts(self):
        rv = []
        portalNum = 0
        for d in self.ind.decls:
            if d.type == 'Interface':
                rv.append('    interrupts_v[%s] = %sWrapper.interrupt;\n' % (portalNum, d.subinterfacename))
                portalNum = portalNum+1
        return ''.join(rv)

    def collectIndicationCtrls(self):
        rv = []
        portalNum = 0
        for d in self.ind.decls:
            if d.type == 'Interface':
                rv.append('    ctrls_v[%s] = %sWrapper.ctrl;\n' % (portalNum, d.subinterfacename))
                portalNum = portalNum+1
        return ''.join(rv)


    def generateIndicationIfc(self):
        rv = []
        ind_bsv_type = self.ind.interfaceType().toBsvType()
        ind_bsv_name = 'indication'
        rv.append('    %s %s = (interface %s;' % (ind_bsv_type, ind_bsv_name, ind_bsv_type))
        for d in self.ind.decls:
            if d.type == 'Interface':
                bsv_type = d.interfaceType().toBsvType()
                rv.append('\n        interface %s %s = %sWrapper.indication;' % (bsv_type, d.subinterfacename, d.subinterfacename))
        rv.append('\n    endinterface);\n')
        return ''.join(rv)

    def collectRequestWrappers(self):
        rv = []
        for d in self.decls:
            if d.type == 'Interface' and  syntax.globalvars.has_key(d.name):
                bsv_type = d.interfaceType().toBsvType()
                request = '%s.%s' % (util.decapitalize(self.name), util.decapitalize(d.subinterfacename))
                # this is a horrible hack (mdk)
                indication = '%sWrapper' % re.sub('Request', 'Indication', (util.decapitalize(d.subinterfacename)))
                rv.append('    %sWrapper %sWrapper <- mk%sWrapper(%s,%s);\n' % (bsv_type, d.subinterfacename, bsv_type, request, indication))
        return rv
            

    def collectIndicationWrappers(self):
        rv = []
        for d in self.ind.decls:
            if d.type == 'Interface':
                bsv_type = d.interfaceType().toBsvType()
                rv.append('    %sWrapper %sWrapper <- mk%sWrapper();\n' % (bsv_type, d.subinterfacename, bsv_type))
        return rv

    def emitBsvImplementationRequest(self,f):
        # print self.name
        requestElements = self.collectRequestElements(self.name)
        methodNames = self.collectMethodNames(self.name)
        methodRuleNames = self.collectMethodRuleNames(self.name)
        methodRules = self.collectMethodRules(self.name)
        axiMasters = self.collectInterfaceNames('Axi[34]Client', True)
        axiSlaves = self.collectInterfaceNames('AxiSlave')
        hdmiInterfaces = self.collectInterfaceNames('HDMI')
        ledInterfaces = self.collectInterfaceNames('LEDS')
        dutName = util.decapitalize(self.name)
        methods = [d for d in self.decls if d.type == 'Method' and d.return_type.name == 'Action']
        substs = {
            'dut': dutName,
            'Dut': util.capitalize(self.name),
            'requestElements': ''.join(requestElements),
            'mutexRuleList': '(* mutually_exclusive = "' + (', '.join(methodRuleNames)) + '" *)' if (len(methodRuleNames) > 1) else '',
            'methodRules': ''.join(methodRules),
            'requestFailureRuleNames': "" if len(methodNames) == 0 else '(* descending_urgency = "'+', '.join(['handle$%s$requestFailure' % n for n in methodNames])+'"*)',
            'channelCount': self.channelCount,
            'writeChannelCount': self.channelCount,
            'axiMasterDeclarations': '\n'.join(['    interface Axi3Master#(%s,%s,%s,%s) %s;' % (params[0].numeric(), params[1].numeric(), params[2].numeric(), params[3].numeric(), axiMaster)
                                                for (axiMaster,t,params) in axiMasters]),
            'axiSlaveDeclarations': '\n'.join(['    interface AxiSlave#(32,4) %s;' % axiSlave
                                               for (axiSlave,t,params) in axiSlaves]),
            'axiMasterModules': '\n'.join(['    Axi3Master#(%s,%s,%s,%s) %sMaster <- mkAxi3Master(%s.%s);'
                                           % (params[0].numeric(), params[1].numeric(), params[2].numeric(), params[3].numeric(), axiMaster,dutName,axiMaster)
                                                   for (axiMaster,t,params) in axiMasters]),
            'axiMasterImplementations': '\n'.join(['    interface Axi3Master %s = %sMaster;' % (axiMaster,axiMaster)
                                                   for (axiMaster,t,params) in axiMasters]),
            'axiSlaveImplementations': '\n'.join(['    interface AxiSlave %s = %s.%s;' % (axiSlave,dutName,axiSlave)
                                                  for (axiSlave,t,params) in axiSlaves]),
            'Indication' : self.ind.name
            }
        f.write(requestWrapperInterfaceTemplate % substs)
        f.write(mkRequestWrapperTemplate % substs)

    def emitBsvImplementationIndication(self,f):

        responseElements = self.collectResponseElements(self.name)
        indicationMethodRuleNames = self.collectIndicationMethodRuleNames(self.name)
        indicationMethodRules = self.collectIndicationMethodRules(self.name)
        indicationMethodsOrig = self.collectIndicationMethodsOrig(self.name)
        indicationMethodsAug = self.collectIndicationMethodsAug(self.name)
        indicationMethodDeclsOrig = self.collectIndicationMethodDeclsOrig(self.name)
        indicationMethodDeclsAug  = self.collectIndicationMethodDeclsAug(self.name)
        dutName = util.decapitalize(self.name)
        methods = [d for d in self.decls if d.type == 'Method' and d.return_type.name == 'Action']
        substs = {
            'dut': dutName,
            'Dut': util.capitalize(self.name),
            'responseElements': ''.join(responseElements),
            'mutexRuleList': '(* mutually_exclusive = "' + (', '.join(indicationMethodRuleNames)) + '" *)' if (len(indicationMethodRuleNames) > 1) else '',
            'indicationMethodRules': ''.join(indicationMethodRules),
            'indicationMethodsOrig': ''.join(indicationMethodsOrig),
            'indicationMethodsAug' : ''.join(indicationMethodsAug),
            'indicationMethodDeclsOrig' :''.join(indicationMethodDeclsOrig),
            'indicationMethodDeclsAug' :''.join(indicationMethodDeclsAug),
            'indicationChannelCount': self.channelCount,
            'channelCount': self.channelCount
            }
        f.write(indicationWrapperInterfaceTemplate % substs)
        f.write(mkIndicationWrapperTemplate % substs)
    def emitBsvImplementation(self, f):
        if self.isIndication:
            self.emitBsvImplementationIndication(f)
        else:
            self.emitBsvImplementationRequest(f)

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
                    print 'method %s has no rule' % n.name
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
    def collectIndicationMethodsOrig(self,outerTypeName):
        methods = []
        for m in self.decls:
            if m.type == 'Method' and not m.aug:
                methodRule = m.collectIndicationMethod(outerTypeName)
                if methodRule:
                    methods.append(methodRule)
        return methods
    def collectIndicationMethodsAug(self,outerTypeName):
        methods = []
        for m in self.decls:
            if m.type == 'Method' and m.aug:
                methodRule = m.collectIndicationMethod(outerTypeName)
                if methodRule:
                    methods.append(methodRule)
        return methods
    def collectIndicationMethodDeclsOrig(self,outerTypeName):
        methods = []
        for m in self.decls:
            if m.type == 'Method' and not m.aug:
                methodRule = m.collectIndicationMethodDecl(outerTypeName)
                if methodRule:
                    methods.append(methodRule)
        return methods
    def collectIndicationMethodDeclsAug(self,outerTypeName):
        methods = []
        for m in self.decls:
            if m.type == 'Method' and m.aug:
                methodRule = m.collectIndicationMethodDecl(outerTypeName)
                if methodRule:
                    methods.append(methodRule)
        return methods
    def collectInterfaceNames(self, name, use_regex=False):
        interfaceNames = []
        for m in self.decls:
            if use_regex:
                matches = re.match(name, m.name)
            else:
                matches = (name == m.name)
            if m.type == 'Interface' and matches:
                # print ("interface name: {%s}" % (m.name)), m
                # print 'name', name, m.name
                interfaceNames.append((m.subinterfacename, m.name, m.params))
        return interfaceNames
