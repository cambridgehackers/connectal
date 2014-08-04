// Copyright (c) 2014 Quanta Research Cambridge, Inc.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Complex::*;
import FixedPoint::*;
import FPCMult::*;
import Gearbox::*;
import Pipe::*;
import FIFO::*;
import BRAMFIFO::*;
import Vector::*;
import Clocks::*;
import DefaultValue::*;
import DDS::*;

/* note rf signal is 64 bits wide, 2 sample of complex fixed point(0,16)
 */
(* always_enabled *)
interface ChannelSelect;
   interface PipeIn#(Vector#(2, Signal)) rf;
   interface PipeOut#(Signal) if;
   method Action setCoeff(Bit#(10) addr, Bit#(32) value);
endinterface


module mkChannelSelect#(UInt#(10) decimation)(ChannelSelect);
   BRAM_Configure cfg = defaultValue;
   cfg.memorySize = 1024;
   Vector#(2, BRAM2Port#(UInt#(8), Complex#(FixedPoint#(2,23)))) coeffRam <- 
        replicate(mkBRAM2Server(cfg));
   Reg#(UInt#(10)) filterPhase <- mkReg(?);
   FIFO#(Bits#(1)) delayFilterPhase <- mkSizedFIFO(3);  // length > bram read latency


   Reg#(Signal) output <- mkReg(?);
   Vector#(2, FPCMult) mul <- replicate(mkFPCMult());

   Vector#(2, FIFO#(Complex#(Product))) accum <- replicate(mkFIFO());
   FIFO#(Complex#(Product)) ycombined <- mkFIFO();
   FPCMult lo <- mkFPCMult();


   mkConnection(rf, mul.x);

   /* could do this with mkForkVector() but we don't need the extra FIFOs
      since everything is ready every cycle
    */
   rule duplicateSignal;
      let v = rf.first;
      rf.deq();
      mul[0].x.enq(v);
      mul[1].x.enq(v);
   endrule
   
   rule filter_phase;
      if (filterPhase == (decimation - 1))
	 begin
	    filterPhase <= 0;
	    delayFilterPhase.enq(1);
	 end
      else
	 begin
	    filterPhase <= phase + 1;
	    delayFilterPhase.enq(0);
	 end
      coeffRam[0].portB.request.put(BRamRequest{write: False, responseOnWrite: False, address: filterPhase, datain: ?});
      coeffRam[1].portB.request.put(BRamRequest{write: False, responseOnWrite: False, address: filterPhase, datain: ?});
   endrule
   
   rule mulin;
      let c0 <- coeffRam[0].portB.response.get();
      let c1 <- coeffRam[1].portB.response.get();
      let phase <- delayFilterPhase.get();
      
      mul[0].coeffData.enq(CoeffData{a: c0, filterPhase: phase});
      mul[1].coeffData.enq(CoeffData{a: c1, filterPhase: phase});
   endrule
   
   rule muloutaccumin0;
      let m <= mul0.y.get();
      if m.filterPhase 
	 begin
	    accum[0] <= m.y;
	    accumout[0].enq(accum[0]);
	 end
      else
	 begin
	    accum[0] <= accum[0] + m.y;
	 end
   endrule

   rule muloutaccumin1;
      let m <= mul1.y.get();
      if m.filterPhase 
	 begin
	    accum[1] <= m.y;
	    accumout[1].enq(accum[1]);
	 end
      else
	 begin
	    accum[1] <= accum[1] + m.y;
	 end
   endrule

   rule accumoutcombinein;
      let a0 <- accumout[0].get();
      let a1 <- accumout[1].get();
      ycombined.enq(a0 + a1);
   endrule;
   
   rule combineoutloin;
      let yin <- ycombined.get();
      let loin <- dds.osc.get();
      if.x.enq(yin):
      if.coeffData.enq(loin);
   endrule;
   
   
   
   method Action setCoeff(Bit#(10) addr, Bit#(32) value);
      int idx = addr[0];
      coeffRam[idx].portA.request.put(BRamRequest{write: True, responseOnWrite: False, address: addr[8:1], datain: unpack(pack(value))});
   endmethod
      
   interface PipeOut if = toPipeOut(output);
   
endmodule