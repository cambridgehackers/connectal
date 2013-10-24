package BlueScopeRequestWrapper;

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
import Memcpy::*;
import BlueScope::*;
import AxiDMA::*;
import BlueScopeIndicationWrapper::*;
import FIFOF::*;
import BRAMFIFO::*;
import GetPut::*;
import AxiClientServer::*;
import AxiDMA::*;
import BlueScope::*;
import Clocks::*;
import FIFO::*;
import FIFOF::*;
import BRAMFIFO::*;
import GetPut::*;
import AxiDMA::*;
import ClientServer::*;
import FIFOF::*;
import Vector::*;
import GetPut::*;
import ClientServer::*;
import BRAMFIFO::*;
import BRAM::*;
import AxiClientServer::*;
import BRAMFIFOFLevel::*;
import PortalMemory::*;
import SGList::*;




typedef struct {
    Bit#(32) padding;
} Start$Request deriving (Bits);
Bit#(6) start$Offset = 0;

typedef struct {
    Bit#(32) padding;
} Reset$Request deriving (Bits);
Bit#(6) reset$Offset = 1;

typedef struct {
    Bit#(64) mask;
} SetTriggerMask$Request deriving (Bits);
Bit#(6) setTriggerMask$Offset = 2;

typedef struct {
    Bit#(64) value;
} SetTriggerValue$Request deriving (Bits);
Bit#(6) setTriggerValue$Offset = 3;

interface BlueScopeRequestWrapper;


endinterface



(* mutually_exclusive = "axiSlaveWrite$start, axiSlaveWrite$reset, axiSlaveWrite$setTriggerMask, axiSlaveWrite$setTriggerValue" *)
module mkBlueScopeRequestWrapper#(BlueScopeRequest blueScopeRequest, BlueScopeIndicationWrapper iw)(BlueScopeRequestWrapper);

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


    FromBit32#(Start$Request) start$requestFifo <- mkFromBit32();
    rule axiSlaveWrite$start if (axiSlaveWriteAddrFifo.first[14] == 0 && axiSlaveWriteAddrFifo.first[13:8] == start$Offset);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        start$requestFifo.enq(axiSlaveWriteDataFifo.first);
    endrule
    (* descending_urgency = "handle$start$request, handle$start$requestFailure" *)
    rule handle$start$request if (iw.putEnable); // iw.putEnable is always True
        let request = start$requestFifo.first;
        start$requestFifo.deq;
        blueScopeRequest.start();
        requestFiredPulse.send();
    endrule
    rule handle$start$requestFailure;
        iw.putFailed(0);
        start$requestFifo.deq;
        $display("start$requestFailure");
    endrule

    FromBit32#(Reset$Request) reset$requestFifo <- mkFromBit32();
    rule axiSlaveWrite$reset if (axiSlaveWriteAddrFifo.first[14] == 0 && axiSlaveWriteAddrFifo.first[13:8] == reset$Offset);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        reset$requestFifo.enq(axiSlaveWriteDataFifo.first);
    endrule
    (* descending_urgency = "handle$reset$request, handle$reset$requestFailure" *)
    rule handle$reset$request if (iw.putEnable); // iw.putEnable is always True
        let request = reset$requestFifo.first;
        reset$requestFifo.deq;
        blueScopeRequest.reset();
        requestFiredPulse.send();
    endrule
    rule handle$reset$requestFailure;
        iw.putFailed(1);
        reset$requestFifo.deq;
        $display("reset$requestFailure");
    endrule

    FromBit32#(SetTriggerMask$Request) setTriggerMask$requestFifo <- mkFromBit32();
    rule axiSlaveWrite$setTriggerMask if (axiSlaveWriteAddrFifo.first[14] == 0 && axiSlaveWriteAddrFifo.first[13:8] == setTriggerMask$Offset);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        setTriggerMask$requestFifo.enq(axiSlaveWriteDataFifo.first);
    endrule
    (* descending_urgency = "handle$setTriggerMask$request, handle$setTriggerMask$requestFailure" *)
    rule handle$setTriggerMask$request if (iw.putEnable); // iw.putEnable is always True
        let request = setTriggerMask$requestFifo.first;
        setTriggerMask$requestFifo.deq;
        blueScopeRequest.setTriggerMask(request.mask);
        requestFiredPulse.send();
    endrule
    rule handle$setTriggerMask$requestFailure;
        iw.putFailed(2);
        setTriggerMask$requestFifo.deq;
        $display("setTriggerMask$requestFailure");
    endrule

    FromBit32#(SetTriggerValue$Request) setTriggerValue$requestFifo <- mkFromBit32();
    rule axiSlaveWrite$setTriggerValue if (axiSlaveWriteAddrFifo.first[14] == 0 && axiSlaveWriteAddrFifo.first[13:8] == setTriggerValue$Offset);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        setTriggerValue$requestFifo.enq(axiSlaveWriteDataFifo.first);
    endrule
    (* descending_urgency = "handle$setTriggerValue$request, handle$setTriggerValue$requestFailure" *)
    rule handle$setTriggerValue$request if (iw.putEnable); // iw.putEnable is always True
        let request = setTriggerValue$requestFifo.first;
        setTriggerValue$requestFifo.deq;
        blueScopeRequest.setTriggerValue(request.value);
        requestFiredPulse.send();
    endrule
    rule handle$setTriggerValue$requestFailure;
        iw.putFailed(3);
        setTriggerValue$requestFifo.deq;
        $display("setTriggerValue$requestFailure");
    endrule


    (* descending_urgency = "handle$start$requestFailure, handle$reset$requestFailure, handle$setTriggerMask$requestFailure, handle$setTriggerValue$requestFailure" *)
    rule outOfRangeWrite if (axiSlaveWriteAddrFifo.first[14] == 0 && 
                             axiSlaveWriteAddrFifo.first[13:8] >= 4);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        outOfRangeWriteCount <= outOfRangeWriteCount+1;
    endrule



endmodule
endpackage: BlueScopeRequestWrapper