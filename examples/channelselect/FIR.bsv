// Copyright (c) 2014 Quanta Research Cambridge, Inc.

// Permission is hereby granted, free of change, to any person
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
import Pipe::*;
import BRAM::*;
import Vector::*;
import DefaultValue::*;
import DDS::*;

typedef Complex#(FixedPoint#(2,14)) Signal;

(* always_enabled *)
interface ChannelSelect;
   interface PipeIn#(Vector#(2, Signal));
   interface PipeOut#(Signal);
   method Action setCoeff(Bit#(10) addr, Bit#(32) value);
endinterface


module mkFIR#()(ChannelSelect);
   BRAM_Configure cfg = defaultValue;
   cfg.memorySize = 1024;
   BRAM2Port#(UInt#(8), Complex#(FixedPoint#(2,23))) coeffRam <- 
        mkBRAM2Server(cfg);
   Reg#(UInt#(10)) pphase <- mkReg(0);
   Reg#(
   
   rule filter_phase;
      if (pphase == (decimation - 1))
	 pphase <= 0;
      else
	 pphase <= phase + 1;
   endrule
   
   
      
      method Action setCoeff(Bit#(8) addr, Bit#(32) value);
      endmethod
      
endmodule