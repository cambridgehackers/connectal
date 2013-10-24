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
import Memcpy::*;
import BlueScope::*;
import AxiDMA::*;
import CoreIndicationWrapper::*;
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
    Bit#(32) numWords;
} StartCopy$Request deriving (Bits);
Bit#(6) startCopy$Offset = 0;

typedef struct {
    Bit#(32) padding;
} ReadWord$Request deriving (Bits);
Bit#(6) readWord$Offset = 1;

typedef struct {
    Bit#(32) padding;
} GetStateDbg$Request deriving (Bits);
Bit#(6) getStateDbg$Offset = 2;

interface CoreRequestWrapper;


endinterface



(* mutually_exclusive = "axiSlaveWrite$startCopy, axiSlaveWrite$readWord, axiSlaveWrite$getStateDbg" *)
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


    FromBit32#(StartCopy$Request) startCopy$requestFifo <- mkFromBit32();
    rule axiSlaveWrite$startCopy if (axiSlaveWriteAddrFifo.first[14] == 0 && axiSlaveWriteAddrFifo.first[13:8] == startCopy$Offset);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        startCopy$requestFifo.enq(axiSlaveWriteDataFifo.first);
    endrule
    (* descending_urgency = "handle$startCopy$request, handle$startCopy$requestFailure" *)
    rule handle$startCopy$request if (iw.putEnable); // iw.putEnable is always True
        let request = startCopy$requestFifo.first;
        startCopy$requestFifo.deq;
        coreRequest.startCopy(request.numWords);
        requestFiredPulse.send();
    endrule
    rule handle$startCopy$requestFailure;
        iw.putFailed(0);
        startCopy$requestFifo.deq;
        $display("startCopy$requestFailure");
    endrule

    FromBit32#(ReadWord$Request) readWord$requestFifo <- mkFromBit32();
    rule axiSlaveWrite$readWord if (axiSlaveWriteAddrFifo.first[14] == 0 && axiSlaveWriteAddrFifo.first[13:8] == readWord$Offset);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        readWord$requestFifo.enq(axiSlaveWriteDataFifo.first);
    endrule
    (* descending_urgency = "handle$readWord$request, handle$readWord$requestFailure" *)
    rule handle$readWord$request if (iw.putEnable); // iw.putEnable is always True
        let request = readWord$requestFifo.first;
        readWord$requestFifo.deq;
        coreRequest.readWord();
        requestFiredPulse.send();
    endrule
    rule handle$readWord$requestFailure;
        iw.putFailed(1);
        readWord$requestFifo.deq;
        $display("readWord$requestFailure");
    endrule

    FromBit32#(GetStateDbg$Request) getStateDbg$requestFifo <- mkFromBit32();
    rule axiSlaveWrite$getStateDbg if (axiSlaveWriteAddrFifo.first[14] == 0 && axiSlaveWriteAddrFifo.first[13:8] == getStateDbg$Offset);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        getStateDbg$requestFifo.enq(axiSlaveWriteDataFifo.first);
    endrule
    (* descending_urgency = "handle$getStateDbg$request, handle$getStateDbg$requestFailure" *)
    rule handle$getStateDbg$request if (iw.putEnable); // iw.putEnable is always True
        let request = getStateDbg$requestFifo.first;
        getStateDbg$requestFifo.deq;
        coreRequest.getStateDbg();
        requestFiredPulse.send();
    endrule
    rule handle$getStateDbg$requestFailure;
        iw.putFailed(2);
        getStateDbg$requestFifo.deq;
        $display("getStateDbg$requestFailure");
    endrule


    (* descending_urgency = "handle$startCopy$requestFailure, handle$readWord$requestFailure, handle$getStateDbg$requestFailure" *)
    rule outOfRangeWrite if (axiSlaveWriteAddrFifo.first[14] == 0 && 
                             axiSlaveWriteAddrFifo.first[13:8] >= 3);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        outOfRangeWriteCount <= outOfRangeWriteCount+1;
    endrule



endmodule
endpackage: CoreRequestWrapper