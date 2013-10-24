package DMARequestWrapper;

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
import DMAIndicationWrapper::*;
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
    Bit#(32) channelId;
    Bit#(40) pa;
    Bit#(32) bsz;
} ConfigReadChan$Request deriving (Bits);
Bit#(6) configReadChan$Offset = 0;

typedef struct {
    Bit#(32) channelId;
    Bit#(40) pa;
    Bit#(32) bsz;
} ConfigWriteChan$Request deriving (Bits);
Bit#(6) configWriteChan$Offset = 1;

typedef struct {
    Bit#(32) padding;
} GetReadStateDbg$Request deriving (Bits);
Bit#(6) getReadStateDbg$Offset = 2;

typedef struct {
    Bit#(32) padding;
} GetWriteStateDbg$Request deriving (Bits);
Bit#(6) getWriteStateDbg$Offset = 3;

typedef struct {
    Bit#(32) off;
    Bit#(40) addr;
    Bit#(32) len;
} Sglist$Request deriving (Bits);
Bit#(6) sglist$Offset = 4;

interface DMARequestWrapper;


endinterface



(* mutually_exclusive = "axiSlaveWrite$configReadChan, axiSlaveWrite$configWriteChan, axiSlaveWrite$getReadStateDbg, axiSlaveWrite$getWriteStateDbg, axiSlaveWrite$sglist" *)
module mkDMARequestWrapper#(DMARequest dMARequest, DMAIndicationWrapper iw)(DMARequestWrapper);

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


    FromBit32#(ConfigReadChan$Request) configReadChan$requestFifo <- mkFromBit32();
    rule axiSlaveWrite$configReadChan if (axiSlaveWriteAddrFifo.first[14] == 0 && axiSlaveWriteAddrFifo.first[13:8] == configReadChan$Offset);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        configReadChan$requestFifo.enq(axiSlaveWriteDataFifo.first);
    endrule
    (* descending_urgency = "handle$configReadChan$request, handle$configReadChan$requestFailure" *)
    rule handle$configReadChan$request if (iw.putEnable); // iw.putEnable is always True
        let request = configReadChan$requestFifo.first;
        configReadChan$requestFifo.deq;
        dMARequest.configReadChan(request.channelId, request.pa, request.bsz);
        requestFiredPulse.send();
    endrule
    rule handle$configReadChan$requestFailure;
        iw.putFailed(0);
        configReadChan$requestFifo.deq;
        $display("configReadChan$requestFailure");
    endrule

    FromBit32#(ConfigWriteChan$Request) configWriteChan$requestFifo <- mkFromBit32();
    rule axiSlaveWrite$configWriteChan if (axiSlaveWriteAddrFifo.first[14] == 0 && axiSlaveWriteAddrFifo.first[13:8] == configWriteChan$Offset);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        configWriteChan$requestFifo.enq(axiSlaveWriteDataFifo.first);
    endrule
    (* descending_urgency = "handle$configWriteChan$request, handle$configWriteChan$requestFailure" *)
    rule handle$configWriteChan$request if (iw.putEnable); // iw.putEnable is always True
        let request = configWriteChan$requestFifo.first;
        configWriteChan$requestFifo.deq;
        dMARequest.configWriteChan(request.channelId, request.pa, request.bsz);
        requestFiredPulse.send();
    endrule
    rule handle$configWriteChan$requestFailure;
        iw.putFailed(1);
        configWriteChan$requestFifo.deq;
        $display("configWriteChan$requestFailure");
    endrule

    FromBit32#(GetReadStateDbg$Request) getReadStateDbg$requestFifo <- mkFromBit32();
    rule axiSlaveWrite$getReadStateDbg if (axiSlaveWriteAddrFifo.first[14] == 0 && axiSlaveWriteAddrFifo.first[13:8] == getReadStateDbg$Offset);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        getReadStateDbg$requestFifo.enq(axiSlaveWriteDataFifo.first);
    endrule
    (* descending_urgency = "handle$getReadStateDbg$request, handle$getReadStateDbg$requestFailure" *)
    rule handle$getReadStateDbg$request if (iw.putEnable); // iw.putEnable is always True
        let request = getReadStateDbg$requestFifo.first;
        getReadStateDbg$requestFifo.deq;
        dMARequest.getReadStateDbg();
        requestFiredPulse.send();
    endrule
    rule handle$getReadStateDbg$requestFailure;
        iw.putFailed(2);
        getReadStateDbg$requestFifo.deq;
        $display("getReadStateDbg$requestFailure");
    endrule

    FromBit32#(GetWriteStateDbg$Request) getWriteStateDbg$requestFifo <- mkFromBit32();
    rule axiSlaveWrite$getWriteStateDbg if (axiSlaveWriteAddrFifo.first[14] == 0 && axiSlaveWriteAddrFifo.first[13:8] == getWriteStateDbg$Offset);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        getWriteStateDbg$requestFifo.enq(axiSlaveWriteDataFifo.first);
    endrule
    (* descending_urgency = "handle$getWriteStateDbg$request, handle$getWriteStateDbg$requestFailure" *)
    rule handle$getWriteStateDbg$request if (iw.putEnable); // iw.putEnable is always True
        let request = getWriteStateDbg$requestFifo.first;
        getWriteStateDbg$requestFifo.deq;
        dMARequest.getWriteStateDbg();
        requestFiredPulse.send();
    endrule
    rule handle$getWriteStateDbg$requestFailure;
        iw.putFailed(3);
        getWriteStateDbg$requestFifo.deq;
        $display("getWriteStateDbg$requestFailure");
    endrule

    FromBit32#(Sglist$Request) sglist$requestFifo <- mkFromBit32();
    rule axiSlaveWrite$sglist if (axiSlaveWriteAddrFifo.first[14] == 0 && axiSlaveWriteAddrFifo.first[13:8] == sglist$Offset);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        sglist$requestFifo.enq(axiSlaveWriteDataFifo.first);
    endrule
    (* descending_urgency = "handle$sglist$request, handle$sglist$requestFailure" *)
    rule handle$sglist$request if (iw.putEnable); // iw.putEnable is always True
        let request = sglist$requestFifo.first;
        sglist$requestFifo.deq;
        dMARequest.sglist(request.off, request.addr, request.len);
        requestFiredPulse.send();
    endrule
    rule handle$sglist$requestFailure;
        iw.putFailed(4);
        sglist$requestFifo.deq;
        $display("sglist$requestFailure");
    endrule


    (* descending_urgency = "handle$configReadChan$requestFailure, handle$configWriteChan$requestFailure, handle$getReadStateDbg$requestFailure, handle$getWriteStateDbg$requestFailure, handle$sglist$requestFailure" *)
    rule outOfRangeWrite if (axiSlaveWriteAddrFifo.first[14] == 0 && 
                             axiSlaveWriteAddrFifo.first[13:8] >= 5);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        outOfRangeWriteCount <= outOfRangeWriteCount+1;
    endrule



endmodule
endpackage: DMARequestWrapper