
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

interface EchoWrapper;
   method Bit#(1) interrupt();
   interface Axi3Slave#(32,32,4) ctrl;
endinterface: EchoWrapper

module mkEchoWrapper(EchoWrapper);

    Reg#(Bit#(32)) scratchpadReg <- mkReg(32'hd00df00d);

    Reg#(Bit#(17)) axiSlaveReadAddrReg <- mkReg(0);
    Reg#(Bit#(17)) axiSlaveWriteAddrReg <- mkReg(0);
    Reg#(Bit#(12)) axiSlaveReadIdReg <- mkReg(0);
    Reg#(Bit#(12)) axiSlaveWriteIdReg <- mkReg(0);
    Reg#(Bit#(4)) axiSlaveReadBurstCountReg <- mkReg(0);
    Reg#(Bit#(4)) axiSlaveWriteBurstCountReg <- mkReg(0);
    Reg#(Bit#(32)) outOfRangeWriteCount <- mkReg(0);
    FIFO#(Bit#(2)) axiSlaveBrespFifo <- mkFIFO();
    FIFO#(Bit#(12)) axiSlaveBidFifo <- mkFIFO();

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

                axiSlaveBrespFifo.enq(0);
                axiSlaveBidFifo.enq(axiSlaveWriteIdReg);

		scratchpadReg <= v;

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
                return axiSlaveReadBurstCountReg == 1 ? 1 : 0;
            endmethod
            method Bit#(12) rid();
                return axiSlaveReadIdReg;
            endmethod
            method ActionValue#(Bit#(32)) readData() if (axiSlaveReadBurstCountReg > 0);
	        axiSlaveReadBurstCountReg <= axiSlaveReadBurstCountReg - 1;
                let v = scratchpadReg;
                return v;
            endmethod
        endinterface
    endinterface

endmodule
