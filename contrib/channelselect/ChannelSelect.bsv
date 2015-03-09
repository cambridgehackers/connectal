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
import SDRTypes::*;
import FPCMult::*;
import Gearbox::*;
import Pipe::*;
import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
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
   method Action setCoeff(Bit#(11) addr, Complex#(FixedPoint#(2,23)) value);
endinterface


module mkChannelSelect#(Bit#(10) decimation, DDS dds)(ChannelSelect);
   BRAM_Configure cfg = defaultValue;
   cfg.memorySize = 1024;
   BRAM2Port#(Bit#(10), Complex#(FixedPoint#(2,23))) coeffRam0 <- 
       mkBRAM2Server(cfg);
   BRAM2Port#(Bit#(10), Complex#(FixedPoint#(2,23))) coeffRam1 <- 
       mkBRAM2Server(cfg);
   Reg#(Bit#(10)) filterPhase <- mkReg(0);
   FIFO#(Bit#(1)) delayFilterPhase <- mkSizedFIFO(3);  // length > bram read latency
   FIFOF#(Vector#(2, Complex#(Signal))) infifo <- mkFIFOF();
   FIFOF#(Complex#(Signal)) outfifo <- mkFIFOF();
   Vector#(2, FPCMult) mul <- replicateM(mkFPCMult());
   Vector#(2, Reg#(Complex#(Product))) accum <- replicateM(mkReg(?));
   Vector#(2, FIFO#(Complex#(Product))) accumout <- replicateM(mkFIFO());
   FIFO#(Complex#(Product)) ycombined <- mkFIFO();
   FPCMult lo <- mkFPCMult();

   /* could do this with mkForkVector() but we don't need the extra FIFOs
      since everything is ready every cycle
    */
   rule duplicateSignal;
      let v = infifo.first;
      infifo.deq();
      mul[0].x.enq(v[0]);
      mul[1].x.enq(v[1]);
   endrule
   
   rule filter_phase;
      $display("filter_phase %d dec %d\n", filterPhase, decimation
);
      if (filterPhase == (decimation - 1))
	 begin
	    filterPhase <= 0;
	    delayFilterPhase.enq(1);
	 end
      else
	 begin
	    filterPhase <= filterPhase + 1;
	    delayFilterPhase.enq(0);
	 end
      coeffRam0.portB.request.put(BRAMRequest{write: False, responseOnWrite: False, address: filterPhase, datain: ?});
      coeffRam1.portB.request.put(BRAMRequest{write: False, responseOnWrite: False, address: filterPhase, datain: ?});
   endrule
   
   rule mulin;
      let c0 <- coeffRam0.portB.response.get();
      let c1 <- coeffRam1.portB.response.get();
      Bit#(1) phase = delayFilterPhase.first();
      $write("mulin ph %d c0 ", phase);
      $write(fshow(c0));
      $write(" c1 ");
      $write(fshow(c1));
      $write("\n");
      
      delayFilterPhase.deq();
      mul[0].a.enq(CoeffData{a: c0, filterPhase: phase});
      mul[1].a.enq(CoeffData{a: c1, filterPhase: phase});
   endrule
   
   rule muloutaccumin0;
      ProductData m = mul[0].y.first();
      mul[0].y.deq();
      if (m.filterPhase == 1)
	 begin
	    accum[0] <= m.y;
	    $write("muloutaccumin0 ph 1 ");
	    $display(fshow(m.y));
	    accumout[0].enq(accum[0]);
	 end
      else
	 begin
	    $write("muloutaccumin0 ph 0 ");
	    $display(fshow(m.y));
	    accum[0] <= accum[0] + m.y;
	 end
   endrule

   rule muloutaccumin1;
      ProductData m = mul[1].y.first();
      mul[1].y.deq();
      if (m.filterPhase == 1)
	 begin
	    $write("muloutaccumin1 ph 1 ");
	    $display(fshow(m.y));
	    accum[1] <= m.y;
	    accumout[1].enq(accum[1]);
	 end
      else
	 begin
	    $write("muloutaccumin0 ph 0 ");
	    $display(fshow(m.y));
	    accum[1] <= accum[1] + m.y;
	 end
   endrule

   rule accumoutcombinein;
      Complex#(Product) a0 = accumout[0].first();
      Complex#(Product) a1 = accumout[1].first();
      ycombined.enq(a0 + a1);
      accumout[0].deq();
      accumout[1].deq();
   endrule
   
   rule combineoutloin;
      Complex#(Product) yin = ycombined.first();
      FixedPoint#(2,16) yrel = fxptTruncate(yin.rel);
      FixedPoint#(2,16) yimg = fxptTruncate(yin.img);
      DDSOutType loin = dds.osc.first();
      dds.osc.deq();
      ycombined.deq();
      lo.x.enq(Complex{rel: yrel, img: yimg});
      lo.a.enq(CoeffData{a: loin, filterPhase: 0});
      $write("combineoutloin x ");
      $write(fshow(Complex{rel: yrel, img: yimg}));
      $write(" loin ");
      $display(fshow(loin));
   endrule
   
   rule loout;
      Complex#(Product) ifc = lo.y.first().y;
      FixedPoint#(2,16) ifrel = fxptTruncate(ifc.rel);
      FixedPoint#(2,16) ifimg = fxptTruncate(ifc.img);
      outfifo.enq(Complex{rel: ifrel, img: ifimg});
      lo.y.deq();
      $write("loout ");
      $display(fshow(Complex{rel: ifrel, img: ifimg}));
   endrule
   
   interface PipeIn rfreq = toPipeIn(infifo);
   
   method Action setCoeff(Bit#(11) addr, Complex#(FixedPoint#(2,23)) value);
      Bit#(1) idx = addr[0];
      if (idx == 0)
	 coeffRam0.portA.request.put(BRAMRequest{write: True, responseOnWrite: False, address: addr[10:1], datain: value});
      else
	 coeffRam1.portA.request.put(BRAMRequest{write: True, responseOnWrite: False, address: addr[10:1], datain: value});
   endmethod
      
   interface PipeOut ifreq = toPipeOut(outfifo);
   
endmodule