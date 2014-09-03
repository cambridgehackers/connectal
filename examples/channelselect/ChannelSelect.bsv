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
import FIFOF::*;
import BRAM::*;
import BRAMFIFO::*;
import Vector::*;
import Clocks::*;
import DefaultValue::*;
import DDS::*;

/* note rf signal is 64 bits wide, 2 sample of complex fixed point(0,16)
 */
(* always_enabled *)
interface ChannelSelect;
   interface PipeIn#(Vector#(2, Complex#(Signal))) rfreq;
   interface PipeOut#(Complex#(Signal)) ifreq;
   method Action setCoeff(Bit#(10) addr, Complex#(FixedPoint#(2, 23)) value);
endinterface


module mkChannelSelect#(UInt#(10) decimation)(ChannelSelect)
   provisos(Bits#(CoeffData, a__),
	    Bits#(ProductData, b__));
   BRAM_Configure cfg = defaultValue;
   cfg.memorySize = 1024;
   BRAM2Port#(UInt#(8), Complex#(FixedPoint#(2,23))) coeffRam0 <- 
       mkBRAM2Server(cfg);
   BRAM2Port#(UInt#(8), Complex#(FixedPoint#(2,23))) coeffRam1 <- 
       mkBRAM2Server(cfg);
   Reg#(UInt#(10)) filterPhase <- mkReg(?);
   FIFO#(Bit#(1)) delayFilterPhase <- mkSizedFIFO(3);  // length > bram read latency


   FIFOF#(Vector#(2, Signal)) infifo <- mkFIFOF();
   FIFOF#(Vector#(2, Signal)) outfifo <- mkFIFOF();
   Vector#(2, FPCMult) mul <- replicateM(mkFPCMult());

   Vector#(2, Reg#(Complex#(Product))) accum <- replicateM(mkReg(?));
   Vector#(2, FIFOF#(Complex#(Product))) accumout <- replicateM(mkPipelineFIFOF());
   
   FIFOF#(Complex#(Product)) ycombined <- mkPipelineFIFOF();
   FPCMult lo <- mkFPCMult();

   /* could do this with mkForkVector() but we don't need the extra FIFOs
      since everything is ready every cycle
    */
   rule duplicateSignal;
      let v = infifo.first;
      infifo.deq();
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
      coeffRam0.portB.request.put(BRamRequest{write: False, responseOnWrite: False, address: filterPhase, datain: ?});
      coeffRam1.portB.request.put(BRamRequest{write: False, responseOnWrite: False, address: filterPhase, datain: ?});
   endrule
   
   rule mulin;
      let c0 <- coeffRam0.portB.response.get();
      let c1 <- coeffRam1.portB.response.get();
      let phase <- delayFilterPhase.get();
      
      mul[0].a.enq(CoeffData{a: c0, filterPhase: phase});
      mul[1].a.enq(CoeffData{a: c1, filterPhase: phase});

   endrule
   
   rule muloutaccumin0;
      let m <- mul[0].y.get();
      if (m.filterPhase)
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
      let m <- mul[1].y.get();
      if (m.filterPhase)
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
   endrule
   
   rule combineoutloin;
      let yin <- ycombined.get();
      let loin <- dds.osc.get();
      lo.x.enq(yin);
      lo.a.enq(CoeffData{a: loin, filterPhase: 0});
   endrule
   
   rule loout;
      let y <- lo.y;
      outfifo.enq(y.y);
   endrule
   
   interface PipeIn rfreq = toPipeIn(infifo);
   
   method Action setCoeff(Bit#(10) addr, Bit#(32) value);
      int idx = addr[0];
      if (idx == 0)
	 coeffRam0.portA.request.put(BRamRequest{write: True, responseOnWrite: False, address: addr[8:1], datain: unpack(pack(value))});
      else
	 coeffRam1.portA.request.put(BRamRequest{write: True, responseOnWrite: False, address: addr[8:1], datain: unpack(pack(value))});
   endmethod
      
   interface PipeOut ifreq = toPipeOut(outfifo);
   
endmodule