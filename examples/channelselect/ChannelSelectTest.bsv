// Copyright (c) 2013 Quanta Research Cambridge, Inc.

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

import Gearbox::*;
import ChannelSelect::*;

interface ChannelSelectTestRequest;
   method Action rfreqDataWrite(Complex#(Signal) data);
   method Action setCoeff(Bit#(10) addr, Complex#(FixedPoint#(2, 23)) value);
endinterface

interface ChannelSelectTestIndication;
   method Action ifreqData(Complex#(Signal) data);
endinterface

module mkChannelSelectTestRequest#(ChannelSelectTestIndication indication) (ChannelSelectTestRequest);
   Clock clk <- exposeCurrentClock;
   Reset rst <- exposeCurrentReset;
   Gearbox#(1, 2, Complex#(Signal)) gb <- mk1toNGearbox(clk, rst, clk, rst);
   ChannelSelect cs <- mkChannelSelect(64);
   
   rule processRF;
      let data = gb.first();
      gb.deq();
      cs.rfreq.enq(data);
   endrule
   
   rule processIF;
      let data = cs.ifreq.first();
      cs.ifreq.deq();
      indication.ifreqData(data);
   endrule
   
   method Action rfreqDataWrite(Complex#(Signal) data);
      gb.enq(data);
   endmethod

   method Action setCoeff(Bit#(10) addr, Complex#(FixedPoint#(2, 23)) value);
      cs.setCoeff(addr, value);
   endmethod
endmodule


