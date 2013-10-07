package CoreEchoIndicationWrapper;

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
import SpecialFIFOs::*;
import AxiDMA::*;
import Echo::*;
import PCIE::*;



typedef struct {
    Bit#(32) v;
} Heard$Response deriving (Bits);
Bit#(6) heard$Offset = 0;

typedef struct {
    Bit#(16) a;
    Bit#(16) b;
} Heard2$Response deriving (Bits);
Bit#(6) heard2$Offset = 1;

typedef struct {
    Bit#(32) v;
} PutFailed$Response deriving (Bits);
Bit#(6) putFailed$Offset = 2;

interface RequestWrapperCommFIFOs;
    interface FIFO#(Bit#(15)) axiSlaveWriteAddrFifo;
    interface FIFO#(Bit#(15)) axiSlaveReadAddrFifo;
    interface FIFO#(Bit#(32)) axiSlaveWriteDataFifo;
    interface FIFO#(Bit#(32)) axiSlaveReadDataFifo;
endinterface

interface CoreEchoIndicationWrapper;
    interface Axi3Slave#(32,32,4,SizeOf#(TLPTag)) ctrl;
    interface ReadOnly#(Bit#(1)) interrupt;
    interface CoreEchoIndication indication;
    interface RequestWrapperCommFIFOs rwCommFifos;
    method Action putFailed(Bit#(32) v);
endinterface


module mkCoreEchoIndicationWrapper(CoreEchoIndicationWrapper);

    // indication-specific state
    Reg#(Bit#(32)) responseFiredCntReg <- mkReg(0);
    Vector#(3, PulseWire) responseFiredWires <- replicateM(mkPulseWire);
    Reg#(Bit#(32)) outOfRangeReadCountReg <- mkReg(0);
    Vector#(3, PulseWire) readOutstanding <- replicateM(mkPulseWire);
    
    function Bool my_or(Bool a, Bool b) = a || b;
    function Bool read_wire (PulseWire a) = a._read;    
    Reg#(Bool) interruptEnableReg <- mkReg(False);
    let       interruptStatus = fold(my_or, map(read_wire, readOutstanding));
    function Bit#(32) read_wire_cvt (PulseWire a) = a._read ? 32'b1 : 32'b0;
    function Bit#(32) my_add(Bit#(32) a, Bit#(32) b) = a+b;

    // state used to implement Axi Slave interface
    Reg#(Bit#(32)) getWordCount <- mkReg(0);
    Reg#(Bit#(32)) putWordCount <- mkReg(0);
    Reg#(Bit#(15)) axiSlaveReadAddrReg <- mkReg(0);
    Reg#(Bit#(15)) axiSlaveWriteAddrReg <- mkReg(0);
    Reg#(Bit#(SizeOf#(TLPTag))) axiSlaveReadIdReg <- mkReg(0);
    Reg#(Bit#(SizeOf#(TLPTag))) axiSlaveWriteIdReg <- mkReg(0);
    FIFO#(Bit#(1)) axiSlaveReadLastFifo <- mkPipelineFIFO;
    FIFO#(Bit#(SizeOf#(TLPTag))) axiSlaveReadIdFifo <- mkPipelineFIFO;
    Reg#(Bit#(4)) axiSlaveReadBurstCountReg <- mkReg(0);
    Reg#(Bit#(4)) axiSlaveWriteBurstCountReg <- mkReg(0);
    FIFO#(Bit#(2)) axiSlaveBrespFifo <- mkFIFO();
    FIFO#(Bit#(SizeOf#(TLPTag))) axiSlaveBidFifo <- mkFIFO();

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
        if (addr >= 14'h020 && addr <= (14'h024 + 3/4))
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


    ToBit32#(Heard$Response) heard$responseFifo <- mkToBit32();
    rule heard$axiSlaveRead if (axiSlaveReadAddrFifo.first[14] == 0 && 
                                         axiSlaveReadAddrFifo.first[13:8] == heard$Offset);
        axiSlaveReadAddrFifo.deq;
        heard$responseFifo.deq;
        axiSlaveReadDataFifo.enq(heard$responseFifo.first);
    endrule
    rule heard$axiSlaveReadOutstanding if (heard$responseFifo.notEmpty);
        readOutstanding[0].send();
    endrule

    ToBit32#(Heard2$Response) heard2$responseFifo <- mkToBit32();
    rule heard2$axiSlaveRead if (axiSlaveReadAddrFifo.first[14] == 0 && 
                                         axiSlaveReadAddrFifo.first[13:8] == heard2$Offset);
        axiSlaveReadAddrFifo.deq;
        heard2$responseFifo.deq;
        axiSlaveReadDataFifo.enq(heard2$responseFifo.first);
    endrule
    rule heard2$axiSlaveReadOutstanding if (heard2$responseFifo.notEmpty);
        readOutstanding[1].send();
    endrule

    ToBit32#(PutFailed$Response) putFailed$responseFifo <- mkToBit32();
    rule putFailed$axiSlaveRead if (axiSlaveReadAddrFifo.first[14] == 0 && 
                                         axiSlaveReadAddrFifo.first[13:8] == putFailed$Offset);
        axiSlaveReadAddrFifo.deq;
        putFailed$responseFifo.deq;
        axiSlaveReadDataFifo.enq(putFailed$responseFifo.first);
    endrule
    rule putFailed$axiSlaveReadOutstanding if (putFailed$responseFifo.notEmpty);
        readOutstanding[2].send();
    endrule


    rule outOfRangeRead if (axiSlaveReadAddrFifo.first[14] == 0 && 
                            axiSlaveReadAddrFifo.first[13:8] >= 3);
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
				    Bit#(SizeOf#(TLPTag)) awid)
                          if (axiSlaveWriteBurstCountReg == 0);
                 axiSlaveWS <= addr[15];
                 axiSlaveWriteBurstCountReg <= burstLen + 1;
                 axiSlaveWriteAddrReg <= truncate(addr);
		 axiSlaveWriteIdReg <= awid;
            endmethod
            method Action writeData(Bit#(32) v, Bit#(4) byteEnable, Bit#(1) last)
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
                    axiSlaveBidFifo.enq(axiSlaveWriteIdReg);
                end
            endmethod
            method ActionValue#(Bit#(2)) writeResponse();
                axiSlaveBrespFifo.deq;
                return axiSlaveBrespFifo.first;
            endmethod
            method ActionValue#(Bit#(SizeOf#(TLPTag))) bid();
                axiSlaveBidFifo.deq;
                return axiSlaveBidFifo.first;
            endmethod
        endinterface
        interface Axi3SlaveRead read;
            method Action readAddr(Bit#(32) addr, Bit#(4) burstLen, Bit#(3) burstWidth,
                                   Bit#(2) burstType, Bit#(3) burstProt, Bit#(4) burstCache, Bit#(SizeOf#(TLPTag)) arid)
                          if (axiSlaveReadBurstCountReg == 0);
                 axiSlaveRS <= addr[15];
                 axiSlaveReadBurstCountReg <= burstLen + 1;
                 axiSlaveReadAddrReg <= truncate(addr);
	    	 axiSlaveReadIdReg <= arid;
            endmethod
            method Bit#(1) last();
                return axiSlaveReadLastFifo.first;
            endmethod
            method Bit#(SizeOf#(TLPTag)) rid();
                return axiSlaveReadIdFifo.first;
            endmethod
            method ActionValue#(Bit#(32)) readData();

                let v = axiSlaveReadDataFifos[axiSlaveRS].first;
                axiSlaveReadDataFifo.deq;
                axiSlaveReadLastFifo.deq;
                axiSlaveReadIdFifo.deq;

                getWordCount <= getWordCount + 1;
                return v;
            endmethod
        endinterface
    endinterface

    interface ReadOnly interrupt;
        method Bit#(1) _read();
            if (interruptEnableReg && interruptStatus)
                return 1'd1;
            else
                return 1'd0;
        endmethod
    endinterface
    interface CoreEchoIndication indication;

    method Action heard(Bit#(32) v);
        heard$responseFifo.enq(Heard$Response {v: v});
        responseFiredWires[0].send();
    endmethod
    method Action heard2(Bit#(16) a, Bit#(16) b);
        heard2$responseFifo.enq(Heard2$Response {a: a, b: b});
        responseFiredWires[1].send();
    endmethod
    endinterface

    method Action putFailed(Bit#(32) v);
        putFailed$responseFifo.enq(PutFailed$Response {v: v});
        responseFiredWires[2].send();
    endmethod

endmodule

endpackage: CoreEchoIndicationWrapper