
// Copyright (c) 2013 Quanta Research Cambridge, Inc.
//
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


import Vector::*;
import Clocks::*;

module mkSyncBits#(a initValue, Clock sClkIn, Reset sRst, Clock dClkIn, Reset dRst)(SyncBitIfc#(a))
   provisos (Bits#(a,awidth));
   
   Reg#(a) ff0 <- mkReg(initValue, clocked_by sClkIn, reset_by sRst);
   Reg#(a) ff1 <- mkReg(initValue, clocked_by dClkIn, reset_by dRst);
   Reg#(a) ff2 <- mkReg(initValue, clocked_by dClkIn, reset_by dRst);

   ReadOnly#(a) ff0cross <- mkNullCrossingWire(dClkIn, ff0);

   rule update;
      ff1 <= ff0cross;
      ff2 <= ff1;
   endrule

   method a read();
      return ff2;
   endmethod: read

   method Action send(a value);
      ff0 <= value;
   endmethod: send
endmodule
