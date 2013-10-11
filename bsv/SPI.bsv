
import Clocks      :: *;
import GetPut      :: *;
import FIFO        :: *;
import Connectable :: *;
import StmtFSM     :: *;
import SpecialFIFOs:: *;

interface SpiPins;
    method Bit#(1) dout();
    method Bit#(1) sel();
    method Action din(Bit#(1) v);
   // inverted clock
   interface Clock clk; 
endinterface: SpiPins

interface SPI#(type a);
   interface Put#(a) request;
   interface Get#(a) response;
   interface SpiPins pins;
   // Clock used by SPI internal state
   interface Clock clock;
   // Reset used by SPI internal state
   interface Reset reset;
endinterface

module mkSpiShifter(SPI#(a)) provisos(Bits#(a,awidth),Add#(1,awidth1,awidth),Log#(awidth,logawidth));

   ClockDividerIfc clockInverter <- mkClockInverter;
   Clock spiClock = clockInverter.slowClock;
   Reset spiReset <-  mkAsyncResetFromCR(2, clockInverter.slowClock);
   Reg#(Bit#(awidth)) shiftreg <- mkReg(unpack(0));
   Reg#(Bit#(1)) selreg <- mkReg(1);
   Reg#(Bit#(logawidth)) countreg <- mkReg(0);
   FIFO#(a) resultFifo <- mkFIFO;

   interface Put request;
      method Action put(a v) if (countreg == 0);
	 selreg <= 0;
	 shiftreg <= pack(v);
	 countreg <= fromInteger(valueOf(awidth));
      endmethod
   endinterface: request

   interface Get response;
      method ActionValue#(a) get();
	 resultFifo.deq;
	 return resultFifo.first;
      endmethod
   endinterface: response

   interface SpiPins pins;
      method Bit#(1) dout();
         return shiftreg[0];
      endmethod
      method Bit#(1) sel() if (countreg > 0);
	 return selreg;
      endmethod
      method Action din(Bit#(1) v) if (countreg > 0);
	 countreg <= countreg - 1;
         Bit#(awidth) newshiftreg = { v, shiftreg[valueOf(awidth)-1:1] };
	 shiftreg <= newshiftreg;
         if (countreg == 1) begin
	    resultFifo.enq(unpack(newshiftreg));
	    selreg <= 1;
	 end
      endmethod
   interface Clock clk = spiClock;
   endinterface: pins
   interface clock = clockInverter.slowClock;
   interface reset = spiReset;
endmodule: mkSpiShifter

module mkSPI#(Integer divisor)(SPI#(a)) provisos(Bits#(a,awidth),Add#(1,awidth1,awidth),Log#(awidth,logawidth));
   ClockDividerIfc clockDivider <- mkClockDivider(divisor);
   Reset slowReset <- mkAsyncResetFromCR(2, clockDivider.slowClock);
   SPI#(a) spi <- mkSpiShifter(clocked_by clockDivider.slowClock, reset_by slowReset);

   SyncFIFOIfc#(a) requestFifo <- mkSyncFIFOFromCC(1, clockDivider.slowClock);
   SyncFIFOIfc#(a) responseFifo <- mkSyncFIFOToCC(1, clockDivider.slowClock, slowReset);

   mkConnection(toGet(requestFifo), spi.request);
   mkConnection(spi.response, toPut(responseFifo));

   //interface spiClock = spi.spiClock;
   interface clock = clockDivider.slowClock;
   interface reset = slowReset;
   interface request = toPut(requestFifo);
   interface response = toGet(responseFifo);
   interface pins = spi.pins;
endmodule: mkSPI

module mkSPI20(SPI#(Bit#(20)));
   SPI#(Bit#(20)) spi <- mkSPI(200);
   return spi;
endmodule

module mkSpiTestBench(Empty);
   Bit#(20) slaveV = 20'hfeed0;
   Bit#(20) masterV = 20'h0bafe;

   SPI#(Bit#(20)) spi <- mkSPI(4);
   Reg#(Bit#(20)) slaveCount <- mkReg(20, clocked_by spi.clock, reset_by spi.reset);
   Reg#(Bit#(20)) slaveValue <- mkReg(slaveV, clocked_by spi.clock, reset_by spi.reset);
   Reg#(Bit#(20)) responseValue <- mkReg(0, clocked_by spi.clock, reset_by spi.reset);

   rule slaveIn if (spi.pins.sel == 0);
      spi.pins.din(slaveValue[0]);
      slaveCount <= slaveCount - 1;
      slaveValue <= (slaveValue >> 1);
   endrule

   rule spipins if (spi.pins.sel == 0);
      $display("din=%d dout=%d sel=%d", slaveValue[0], spi.pins.dout, spi.pins.sel);
      responseValue <= { spi.pins.dout, responseValue[19:1] };
   endrule

   rule displaySlaveValue if (slaveCount == 0);
      $display("slave received %h", responseValue);
      if (responseValue != masterV)
	 $finish(-1);
   endrule

   rule finished;
      let result <- spi.response.get();
      $display("master received %h", result);
      if (result == slaveV)
	 $finish(0);
      else
	 $finish(-2);
   endrule

   let once <- mkOnce(action
      $display("master sending %h; slave sending %h", masterV, slaveV);
      spi.request.put(masterV);
      endaction);
   rule foobar;
      once.start();
   endrule

endmodule
