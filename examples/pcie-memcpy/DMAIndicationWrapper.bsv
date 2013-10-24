package DMAIndicationWrapper;

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
    DmaDbgRec rec;
} ReportStateDbg$Response deriving (Bits);
Bit#(6) reportStateDbg$Offset = 0;

typedef struct {
    Bit#(32) channelId;
} ConfigResp$Response deriving (Bits);
Bit#(6) configResp$Offset = 1;

typedef struct {
    Bit#(32) v;
} SglistResp$Response deriving (Bits);
Bit#(6) sglistResp$Offset = 2;

typedef struct {
    Bit#(32) v;
} PutFailed$Response deriving (Bits);
Bit#(6) putFailed$Offset = 3;

interface RequestWrapperCommFIFOs;
    interface FIFO#(Bit#(15)) axiSlaveWriteAddrFifo;
    interface FIFO#(Bit#(15)) axiSlaveReadAddrFifo;
    interface FIFO#(Bit#(32)) axiSlaveWriteDataFifo;
    interface FIFO#(Bit#(32)) axiSlaveReadDataFifo;
endinterface

interface DMAIndicationWrapper;
    interface Axi3Slave#(32,32,4,12) ctrl;
    interface ReadOnly#(Bool) putEnable;
    interface ReadOnly#(Bit#(1)) interrupt;
    interface DMAIndication indication;
    interface RequestWrapperCommFIFOs rwCommFifos;
    method Action putFailed(Bit#(32) v);
endinterface


(* mutually_exclusive = "reportStateDbg$axiSlaveRead, configResp$axiSlaveRead, sglistResp$axiSlaveRead, putFailed$axiSlaveRead" *)
module mkDMAIndicationWrapper(DMAIndicationWrapper) provisos (Log#(4,iccsz));

    // indication-specific state
    Reg#(Bit#(32)) responseFiredCntReg <- mkReg(0);
    Vector#(4, PulseWire) responseFiredWires <- replicateM(mkPulseWire);
    Reg#(Bit#(32)) underflowReadCountReg <- mkReg(0);
    Reg#(Bit#(32)) outOfRangeReadCountReg <- mkReg(0);
    Reg#(Bit#(32)) outOfRangeWriteCount <- mkReg(0);
    ReadyQueue#(4, Bit#(iccsz), Bit#(iccsz)) rq <- mkFirstReadyQueue();
    
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
        if (addr == 14'h020)
	begin
            if (tpl_2(rq.maxPriorityRequest) != 0)
            begin
	        v = extend(tpl_1(rq.maxPriorityRequest)) + 1;
            end
            else
            begin
                v = 0;
            end
	end
	if (addr == 14'h034)
	    v = outOfRangeWriteCount;
	if (addr == 14'h038)
	    v = underflowReadCountReg;
        axiSlaveReadDataFifo.enq(v);
    endrule


    ToBit32#(ReportStateDbg$Response) reportStateDbg$responseFifo <- mkToBit32();
    rule reportStateDbg$axiSlaveRead if (axiSlaveReadAddrFifo.first[14] == 0 && 
                                         axiSlaveReadAddrFifo.first[13:8] == reportStateDbg$Offset);
        axiSlaveReadAddrFifo.deq;
        let v = 32'hbad0dada;
        if (reportStateDbg$responseFifo.notEmpty) begin
            reportStateDbg$responseFifo.deq;
            v = reportStateDbg$responseFifo.first;
        end
        else begin
            underflowReadCountReg <= underflowReadCountReg + 1;
        end
        axiSlaveReadDataFifo.enq(v);
    endrule
    rule reportStateDbg$ReadyBit;
        rq.readyBits[reportStateDbg$Offset] <= reportStateDbg$responseFifo.notEmpty();
    endrule

    ToBit32#(ConfigResp$Response) configResp$responseFifo <- mkToBit32();
    rule configResp$axiSlaveRead if (axiSlaveReadAddrFifo.first[14] == 0 && 
                                         axiSlaveReadAddrFifo.first[13:8] == configResp$Offset);
        axiSlaveReadAddrFifo.deq;
        let v = 32'hbad0dada;
        if (configResp$responseFifo.notEmpty) begin
            configResp$responseFifo.deq;
            v = configResp$responseFifo.first;
        end
        else begin
            underflowReadCountReg <= underflowReadCountReg + 1;
        end
        axiSlaveReadDataFifo.enq(v);
    endrule
    rule configResp$ReadyBit;
        rq.readyBits[configResp$Offset] <= configResp$responseFifo.notEmpty();
    endrule

    ToBit32#(SglistResp$Response) sglistResp$responseFifo <- mkToBit32();
    rule sglistResp$axiSlaveRead if (axiSlaveReadAddrFifo.first[14] == 0 && 
                                         axiSlaveReadAddrFifo.first[13:8] == sglistResp$Offset);
        axiSlaveReadAddrFifo.deq;
        let v = 32'hbad0dada;
        if (sglistResp$responseFifo.notEmpty) begin
            sglistResp$responseFifo.deq;
            v = sglistResp$responseFifo.first;
        end
        else begin
            underflowReadCountReg <= underflowReadCountReg + 1;
        end
        axiSlaveReadDataFifo.enq(v);
    endrule
    rule sglistResp$ReadyBit;
        rq.readyBits[sglistResp$Offset] <= sglistResp$responseFifo.notEmpty();
    endrule

    ToBit32#(PutFailed$Response) putFailed$responseFifo <- mkToBit32();
    rule putFailed$axiSlaveRead if (axiSlaveReadAddrFifo.first[14] == 0 && 
                                         axiSlaveReadAddrFifo.first[13:8] == putFailed$Offset);
        axiSlaveReadAddrFifo.deq;
        let v = 32'hbad0dada;
        if (putFailed$responseFifo.notEmpty) begin
            putFailed$responseFifo.deq;
            v = putFailed$responseFifo.first;
        end
        else begin
            underflowReadCountReg <= underflowReadCountReg + 1;
        end
        axiSlaveReadDataFifo.enq(v);
    endrule
    rule putFailed$ReadyBit;
        rq.readyBits[putFailed$Offset] <= putFailed$responseFifo.notEmpty();
    endrule


    rule outOfRangeRead if (axiSlaveReadAddrFifo.first[14] == 0 && 
                            axiSlaveReadAddrFifo.first[13:8] >= 4);
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
        method Bit#(1) _read();
            if (interruptEnableReg && interruptStatus)
                return 1'd1;
            else
                return 1'd0;
        endmethod
    endinterface
    interface DMAIndication indication;

    method Action reportStateDbg(DmaDbgRec rec);
        reportStateDbg$responseFifo.enq(ReportStateDbg$Response {rec: rec});
        responseFiredWires[0].send();
    endmethod
    method Action configResp(Bit#(32) channelId);
        configResp$responseFifo.enq(ConfigResp$Response {channelId: channelId});
        responseFiredWires[1].send();
    endmethod
    method Action sglistResp(Bit#(32) v);
        sglistResp$responseFifo.enq(SglistResp$Response {v: v});
        responseFiredWires[2].send();
    endmethod
    endinterface

    method Action putFailed(Bit#(32) v);
        putFailed$responseFifo.enq(PutFailed$Response {v: v});
        responseFiredWires[3].send();
    endmethod

endmodule

endpackage: DMAIndicationWrapper