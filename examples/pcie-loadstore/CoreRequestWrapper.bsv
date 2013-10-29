package CoreRequestWrapper;

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
import LoadStore::*;
import CoreIndicationWrapper::*;
import FIFO::*;
import AxiClientServer::*;




typedef struct {
    Bit#(40) addr;
    Bit#(4) length;
} Load$Request deriving (Bits);
Bit#(6) load$Offset = 0;

typedef struct {
    Bit#(40) addr;
    Bit#(64) value;
} Store$Request deriving (Bits);
Bit#(6) store$Offset = 1;

interface CoreRequestWrapper;


endinterface



(* mutually_exclusive = "axiSlaveWrite$load, axiSlaveWrite$store" *)
module mkCoreRequestWrapper#(CoreRequest coreRequest, CoreIndicationWrapper iw)(CoreRequestWrapper);

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


    FromBit32#(Load$Request) load$requestFifo <- mkFromBit32();
    rule axiSlaveWrite$load if (axiSlaveWriteAddrFifo.first[14] == 0 && axiSlaveWriteAddrFifo.first[13:8] == load$Offset);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        load$requestFifo.enq(axiSlaveWriteDataFifo.first);
    endrule
    (* descending_urgency = "handle$load$request, handle$load$requestFailure" *)
    rule handle$load$request if (iw.putEnable); // iw.putEnable is always True
        let request = load$requestFifo.first;
        load$requestFifo.deq;
        coreRequest.load(request.addr, request.length);
        requestFiredPulse.send();
    endrule
    rule handle$load$requestFailure;
        iw.putFailed(0);
        load$requestFifo.deq;
        $display("load$requestFailure");
    endrule

    FromBit32#(Store$Request) store$requestFifo <- mkFromBit32();
    rule axiSlaveWrite$store if (axiSlaveWriteAddrFifo.first[14] == 0 && axiSlaveWriteAddrFifo.first[13:8] == store$Offset);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        store$requestFifo.enq(axiSlaveWriteDataFifo.first);
    endrule
    (* descending_urgency = "handle$store$request, handle$store$requestFailure" *)
    rule handle$store$request if (iw.putEnable); // iw.putEnable is always True
        let request = store$requestFifo.first;
        store$requestFifo.deq;
        coreRequest.store(request.addr, request.value);
        requestFiredPulse.send();
    endrule
    rule handle$store$requestFailure;
        iw.putFailed(1);
        store$requestFifo.deq;
        $display("store$requestFailure");
    endrule


    (* descending_urgency = "handle$load$requestFailure, handle$store$requestFailure" *)
    rule outOfRangeWrite if (axiSlaveWriteAddrFifo.first[14] == 0 && 
                             axiSlaveWriteAddrFifo.first[13:8] >= 2);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        outOfRangeWriteCount <= outOfRangeWriteCount+1;
    endrule



endmodule: mkCoreRequestWrapper
endpackage: CoreRequestWrapper
