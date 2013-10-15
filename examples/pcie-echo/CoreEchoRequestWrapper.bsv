package CoreEchoRequestWrapper;

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
import Echo::*;
import CoreEchoIndicationWrapper::*;
import FIFO::*;
import Zynq::*;




typedef struct {
    Bit#(32) v;
} Say$Request deriving (Bits);
Bit#(6) say$Offset = 0;

typedef struct {
    Bit#(16) a;
    Bit#(16) b;
} Say2$Request deriving (Bits);
Bit#(6) say2$Offset = 1;

typedef struct {
    Bit#(8) v;
} SetLeds$Request deriving (Bits);
Bit#(6) setLeds$Offset = 2;

interface CoreEchoRequestWrapper;


endinterface



(* mutually_exclusive = "axiSlaveWrite$say, axiSlaveWrite$say2, axiSlaveWrite$setLeds" *)
module mkCoreEchoRequestWrapper#(CoreEchoRequest coreEchoRequest, CoreEchoIndicationWrapper iw)(CoreEchoRequestWrapper);

    // request-specific state
    Reg#(Bit#(32)) requestFiredCount <- mkReg(0);
    Reg#(Bit#(32)) overflowCount <- mkReg(0);
    Reg#(Bit#(32)) outOfRangeWriteCount <- mkReg(0);

    let axiSlaveWriteAddrFifo = iw.rwCommFifos.axiSlaveWriteAddrFifo;
    let axiSlaveReadAddrFifo  = iw.rwCommFifos.axiSlaveReadAddrFifo;
    let axiSlaveWriteDataFifo = iw.rwCommFifos.axiSlaveWriteDataFifo;
    let axiSlaveReadDataFifo  = iw.rwCommFifos.axiSlaveReadDataFifo; 


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


    FromBit32#(Say$Request) say$requestFifo <- mkFromBit32();
    rule axiSlaveWrite$say if (axiSlaveWriteAddrFifo.first[14] == 0 && axiSlaveWriteAddrFifo.first[13:8] == say$Offset);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        say$requestFifo.enq(axiSlaveWriteDataFifo.first);
    endrule
    (* descending_urgency = "handle$say$request, handle$say$requestFailure" *)
    rule handle$say$request if (iw.putEnable); // iw.putEnable is always True
        let request = say$requestFifo.first;
        say$requestFifo.deq;
        coreEchoRequest.say(request.v);
        requestFiredCount <= requestFiredCount+1;
    endrule
    rule handle$say$requestFailure;
        iw.putFailed(0);
        say$requestFifo.deq;
        $display("say$requestFailure");
    endrule

    FromBit32#(Say2$Request) say2$requestFifo <- mkFromBit32();
    rule axiSlaveWrite$say2 if (axiSlaveWriteAddrFifo.first[14] == 0 && axiSlaveWriteAddrFifo.first[13:8] == say2$Offset);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        say2$requestFifo.enq(axiSlaveWriteDataFifo.first);
    endrule
    (* descending_urgency = "handle$say2$request, handle$say2$requestFailure" *)
    rule handle$say2$request if (iw.putEnable); // iw.putEnable is always True
        let request = say2$requestFifo.first;
        say2$requestFifo.deq;
        coreEchoRequest.say2(request.a, request.b);
        requestFiredCount <= requestFiredCount+1;
    endrule
    rule handle$say2$requestFailure;
        iw.putFailed(1);
        say2$requestFifo.deq;
        $display("say2$requestFailure");
    endrule

    FromBit32#(SetLeds$Request) setLeds$requestFifo <- mkFromBit32();
    rule axiSlaveWrite$setLeds if (axiSlaveWriteAddrFifo.first[14] == 0 && axiSlaveWriteAddrFifo.first[13:8] == setLeds$Offset);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        setLeds$requestFifo.enq(axiSlaveWriteDataFifo.first);
    endrule
    (* descending_urgency = "handle$setLeds$request, handle$setLeds$requestFailure" *)
    rule handle$setLeds$request if (iw.putEnable); // iw.putEnable is always True
        let request = setLeds$requestFifo.first;
        setLeds$requestFifo.deq;
        coreEchoRequest.setLeds(request.v);
        requestFiredCount <= requestFiredCount+1;
    endrule
    rule handle$setLeds$requestFailure;
        iw.putFailed(2);
        setLeds$requestFifo.deq;
        $display("setLeds$requestFailure");
    endrule


    rule outOfRangeWrite if (axiSlaveWriteAddrFifo.first[14] == 0 && 
                             axiSlaveWriteAddrFifo.first[13:8] >= 3);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        outOfRangeWriteCount <= outOfRangeWriteCount+1;
    endrule



endmodule
endpackage: CoreEchoRequestWrapper