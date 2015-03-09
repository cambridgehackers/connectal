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

import DDS::*;
import Gearbox::*;
import ChannelSelect::*;

import Complex::*;
import SDRTypes::*;
import FPCMult::*;
import FixedPoint::*;
import Pipe::*;
import Vector::*;
import ChannelSelectTestInterfaces::*;


module mkChannelSelectTestRequest#(ChannelSelectTestIndication indication) (ChannelSelectTestRequest)
   provisos(Bits#(CoeffData, a__),
	    Bits#(ProductData, b__),
	    Bits#(MulData, c__));
   Clock clk <- exposeCurrentClock;
   Reset rst <- exposeCurrentReset;
   Gearbox#(1, 2, Complex#(Signal)) gb <- mk1toNGearbox(clk, rst, clk, rst);
   DDS dds <- mkDDS();
   ChannelSelect cs <- mkChannelSelect(4, dds);
   
   rule processRF;
      let data = gb.first();
      gb.deq();
      cs.rfreq.enq(data);
   endrule
   
   rule processIF;
      let data = cs.ifreq.first();
      cs.ifreq.deq();
      indication.ifreqData(zeroExtend(pack(data.rel)), zeroExtend(pack(data.img)));
   endrule
   
   method Action rfreqDataWrite(Bit#(32) dataRe, Bit#(32) dataIm);
      Signal re = unpack(truncate(dataRe));
      Signal im = unpack(truncate(dataIm));
      Vector#(1, Complex#(Signal)) x = newVector();
      x[0] = Complex{rel: re, img: im};
      gb.enq(x);
      indication.setDataResp();
   endmethod

   method Action setCoeff(Bit#(11) addr, Bit#(32) valueRe, Bit#(32) valueIm);
    FixedPoint#(2, 23) re = unpack(pack(truncate(valueRe)));
    FixedPoint#(2, 23) im = unpack(pack(truncate(valueIm)));
      cs.setCoeff(addr, Complex{rel: re, img:im});
      indication.setConfigResp();
   endmethod

   method Action setPhaseAdvance(Bit#(32) i, Bit#(32) f);
    dds.setPhaseAdvance(PhaseType{i: truncate(i), f: truncate(f)});
      indication.setConfigResp();
   endmethod
endmodule


