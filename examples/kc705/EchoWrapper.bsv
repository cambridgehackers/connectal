
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
import Echo::*;




typedef struct {
        Bit#(32) v;
} Say$Request deriving (Bits);
typedef SizeOf#(Say$Request) Say$RequestSize;
Bit#(8) say$Offset = 3;

typedef struct {
        Bit#(16) a;
        Bit#(16) b;
} Say2$Request deriving (Bits);
typedef SizeOf#(Say2$Request) Say2$RequestSize;
Bit#(8) say2$Offset = 4;

typedef struct {
        Bit#(8) v;
} SetLeds$Request deriving (Bits);
typedef SizeOf#(SetLeds$Request) SetLeds$RequestSize;
Bit#(8) setLeds$Offset = 5;



typedef struct {
        Bit#(32) v;
} Heard$Response deriving (Bits);
typedef SizeOf#(Heard$Response) Heard$ResponseSize;
Bit#(8) heard$Offset = 0;

typedef struct {
        Bit#(16) a;
        Bit#(16) b;
} Heard2$Response deriving (Bits);
typedef SizeOf#(Heard2$Response) Heard2$ResponseSize;
Bit#(8) heard2$Offset = 1;

typedef struct {
        Bit#(32) v;
} PutFailed$Response deriving (Bits);
typedef SizeOf#(PutFailed$Response) PutFailed$ResponseSize;
Bit#(8) putFailed$Offset = 2;


interface EchoWrapper;
   method Bit#(1) interrupt();
   interface Axi3Slave#(32,32,4) ctrl;



    interface LEDS leds;


endinterface


interface EchoIndications$Aug;

        method Action heard(Bit#(32) v);
        method Action heard2(Bit#(16) a, Bit#(16) b);
        method Action putFailed(Bit#(32) v);
endinterface

function EchoIndications strip$Aug(EchoIndications$Aug aug);
return (interface EchoIndications;
          
        method Action heard(Bit#(32) v) = aug.heard(v);
        method Action heard2(Bit#(16) a, Bit#(16) b) = aug.heard2(a, b);
        endinterface);
endfunction

interface EchoIndicationsWrapper;
    interface EchoIndications$Aug indications;
    interface Reg#(Bit#(32)) underflowCount;
    interface Reg#(Bit#(32)) responseFiredCnt;
    interface Reg#(Bit#(32)) outOfRangeReadCount;
endinterface

module mkEchoIndicationsWrapper#(FIFO#(Bit#(17)) axiSlaveReadAddrFifo,
                                    FIFO#(Bit#(32)) axiSlaveReadDataFifo,
                                    Vector#(3, PulseWire) readOutstanding )
                                   (EchoIndicationsWrapper);
    Reg#(Bit#(32)) responseFiredCntReg <- mkReg(0);
    Vector#(3, PulseWire) responseFiredWires <- replicateM(mkPulseWire);
    Reg#(Bit#(32)) outOfRangeReadCountReg <- mkReg(0);

    Reg#(Bit#(32)) underflowCountReg <- mkReg(0);

    function Bit#(32) read_wire (PulseWire a) = a._read ? 32'b1 : 32'b0;
    function Bit#(32) my_add(Bit#(32) a, Bit#(32) b) = a+b;
    
    rule increment_responseFiredCntReg;
       responseFiredCntReg <= responseFiredCntReg + fold(my_add, map(read_wire, responseFiredWires));
    endrule
    

    ToBit32#(Heard$Response) heard$responseFifo <- mkToBit32();
    rule heard$axiSlaveRead if (axiSlaveReadAddrFifo.first[16] == 1 && axiSlaveReadAddrFifo.first[15:8] == heard$Offset);
        axiSlaveReadAddrFifo.deq;
        Bit#(8) offset = axiSlaveReadAddrFifo.first[7:0];
        Bit#(32) response = 0;
        if (offset >= 128)
        begin
            response = heard$responseFifo.first;
            heard$responseFifo.deq;
        end
        axiSlaveReadDataFifo.enq(response);
    endrule
    rule heard$axiSlaveReadOutstanding if (heard$responseFifo.notEmpty);
        readOutstanding[0].send();
    endrule

    ToBit32#(Heard2$Response) heard2$responseFifo <- mkToBit32();
    rule heard2$axiSlaveRead if (axiSlaveReadAddrFifo.first[16] == 1 && axiSlaveReadAddrFifo.first[15:8] == heard2$Offset);
        axiSlaveReadAddrFifo.deq;
        Bit#(8) offset = axiSlaveReadAddrFifo.first[7:0];
        Bit#(32) response = 0;
        if (offset >= 128)
        begin
            response = heard2$responseFifo.first;
            heard2$responseFifo.deq;
        end
        axiSlaveReadDataFifo.enq(response);
    endrule
    rule heard2$axiSlaveReadOutstanding if (heard2$responseFifo.notEmpty);
        readOutstanding[1].send();
    endrule

    ToBit32#(PutFailed$Response) putFailed$responseFifo <- mkToBit32();
    rule putFailed$axiSlaveRead if (axiSlaveReadAddrFifo.first[16] == 1 && axiSlaveReadAddrFifo.first[15:8] == putFailed$Offset);
        axiSlaveReadAddrFifo.deq;
        Bit#(8) offset = axiSlaveReadAddrFifo.first[7:0];
        Bit#(32) response = 0;
        if (offset >= 128)
        begin
            response = putFailed$responseFifo.first;
            putFailed$responseFifo.deq;
        end
        axiSlaveReadDataFifo.enq(response);
    endrule
    rule putFailed$axiSlaveReadOutstanding if (putFailed$responseFifo.notEmpty);
        readOutstanding[2].send();
    endrule


    rule outOfRangeRead if (axiSlaveReadAddrFifo.first[16] == 1 && axiSlaveReadAddrFifo.first[15:8] >= 3);
        axiSlaveReadAddrFifo.deq;
        axiSlaveReadDataFifo.enq(0);
        outOfRangeReadCountReg <= outOfRangeReadCountReg+1;
    endrule
    interface EchoIndications$Aug indications;

        method Action heard(Bit#(32) v);
            heard$responseFifo.enq(Heard$Response {v: v});
            responseFiredWires[0].send();
        endmethod

        method Action heard2(Bit#(16) a, Bit#(16) b);
            heard2$responseFifo.enq(Heard2$Response {a: a, b: b});
            responseFiredWires[1].send();
        endmethod

        method Action putFailed(Bit#(32) v);
            putFailed$responseFifo.enq(PutFailed$Response {v: v});
            responseFiredWires[2].send();
        endmethod

    endinterface
    interface Reg outOfRangeReadCount = outOfRangeReadCountReg;
    interface Reg responseFiredCnt = responseFiredCntReg;
    interface Reg underflowCount = underflowCountReg;
endmodule

module mkEchoWrapper(EchoWrapper);

    Reg#(Bit#(32)) requestFiredCntReg <- mkReg(0);
    Vector#(3, PulseWire) requestFiredWires <- replicateM(mkPulseWire);

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
    
    Vector#(3, PulseWire) readOutstanding <- replicateM(mkPulseWire);
    
    EchoIndicationsWrapper indWrapper <- mkEchoIndicationsWrapper(axiSlaveReadAddrFifo,
                                                                        axiSlaveReadDataFifo,
                                                                        readOutstanding);
    EchoIndications$Aug indications$Aug = indWrapper.indications;
    EchoIndications     indications     = strip$Aug(indications$Aug);


    Echo echo <- mkEcho( indications);

    function Bool my_or(Bool a, Bool b) = a || b;
    function Bool read_wire (PulseWire a) = a._read;
    
    Reg#(Bool) interruptEnableReg <- mkReg(False);
    let       interruptStatus = fold(my_or, map(read_wire, readOutstanding));

    Reg#(Bit#(32)) scratchpadReg <- mkReg(32'hd00df00d);

    function Bit#(32) read_wire_cvt (PulseWire a) = a._read ? 32'b1 : 32'b0;
    function Bit#(32) my_add(Bit#(32) a, Bit#(32) b) = a+b;

    rule increment_requestFiredCntReg;
       requestFiredCntReg <= requestFiredCntReg + fold(my_add, map(read_wire_cvt, requestFiredWires));
    endrule


    FromBit32#(Say$Request) say$requestFifo <- mkFromBit32();
    rule axiSlaveWrite$say if (axiSlaveWriteAddrFifo.first[16] == 1 && axiSlaveWriteAddrFifo.first[15:8] == say$Offset);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        say$requestFifo.enq(axiSlaveWriteDataFifo.first);
    endrule
    (* descending_urgency = "handle$say$request, handle$say$requestFailure" *)
    rule handle$say$request;
        let request = say$requestFifo.first;
        say$requestFifo.deq;
        echo.say(request.v);
        requestFiredWires[0].send;
        // support for impCondOf in bsc is questionable (mdk)
        // let success = impCondOf(echo.say(request.v));
        // if (success)
        // echo.say(request.v);
        // else
        // indications$Aug.putFailed(0);
    endrule
    rule handle$say$requestFailure;
        indications$Aug.putFailed(0);
        say$requestFifo.deq;
    endrule

    FromBit32#(Say2$Request) say2$requestFifo <- mkFromBit32();
    rule axiSlaveWrite$say2 if (axiSlaveWriteAddrFifo.first[16] == 1 && axiSlaveWriteAddrFifo.first[15:8] == say2$Offset);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        say2$requestFifo.enq(axiSlaveWriteDataFifo.first);
    endrule
    (* descending_urgency = "handle$say2$request, handle$say2$requestFailure" *)
    rule handle$say2$request;
        let request = say2$requestFifo.first;
        say2$requestFifo.deq;
        echo.say2(request.a, request.b);
        requestFiredWires[1].send;
        // support for impCondOf in bsc is questionable (mdk)
        // let success = impCondOf(echo.say2(request.a, request.b));
        // if (success)
        // echo.say2(request.a, request.b);
        // else
        // indications$Aug.putFailed(1);
    endrule
    rule handle$say2$requestFailure;
        indications$Aug.putFailed(1);
        say2$requestFifo.deq;
    endrule

    FromBit32#(SetLeds$Request) setLeds$requestFifo <- mkFromBit32();
    rule axiSlaveWrite$setLeds if (axiSlaveWriteAddrFifo.first[16] == 1 && axiSlaveWriteAddrFifo.first[15:8] == setLeds$Offset);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
        setLeds$requestFifo.enq(axiSlaveWriteDataFifo.first);
    endrule
    (* descending_urgency = "handle$setLeds$request, handle$setLeds$requestFailure" *)
    rule handle$setLeds$request;
        let request = setLeds$requestFifo.first;
        setLeds$requestFifo.deq;
        echo.setLeds(request.v);
        requestFiredWires[2].send;
        // support for impCondOf in bsc is questionable (mdk)
        // let success = impCondOf(echo.setLeds(request.v));
        // if (success)
        // echo.setLeds(request.v);
        // else
        // indications$Aug.putFailed(2);
    endrule
    rule handle$setLeds$requestFailure;
        indications$Aug.putFailed(2);
        setLeds$requestFifo.deq;
    endrule


    rule writeCtrlReg if (axiSlaveWriteAddrFifo.first[16] == 0);
        axiSlaveWriteAddrFifo.deq;
        axiSlaveWriteDataFifo.deq;
	let addr = axiSlaveWriteAddrFifo.first[11:0];
	let v = axiSlaveWriteDataFifo.first;
	if (addr == 12'h000)
	    noAction; // interruptStatus is read-only
	if (addr == 12'h004)
	    interruptEnableReg <= v[0] == 1'd1; //reduceOr(v) == 1'd1;
	if (addr == 12'h03C)
	    scratchpadReg <= v;
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
	    v = 3; // indicationChannelCount
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
            v = scratchpadReg;
        if (addr >= 12'h040 && addr <= (12'h040 + 3/4))
	begin
	    v = 0;
	    Bit#(7) baseQueueNumber = addr[9:3] << 5;
	    for (Bit#(7) i = 0; i <= baseQueueNumber+31 && i < 3; i = i + 1)
	    begin
		Bit#(5) bitPos = truncate(i - baseQueueNumber);
		// drive value based on which HW->SW FIFOs have pending messages
		v[bitPos] = readOutstanding[i] ? 1'd1 : 1'd0; 
	    end
	end
        axiSlaveReadDataFifo.enq(v);
    endrule

    rule outOfRangeWrite if (axiSlaveWriteAddrFifo.first[16] == 1 && (axiSlaveWriteAddrFifo.first[15:8] < 3 || axiSlaveWriteAddrFifo.first[15:8] >= 6));
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
    interface LEDS leds = echo.leds;
endmodule
