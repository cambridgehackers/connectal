
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

import "BVI" IBUFDS =
module mkIBUFDS#(Wire#(one_bit) i, Wire#(one_bit) ib)(ReadOnly#(one_bit)) provisos(Bits#(one_bit,1));
   default_clock clk();
   default_reset rstn();

   parameter DIFF_TERM = 1;

   port I = i;
   port IB = ib;
   method O    _read;

   path(I, O);
   path(IB, O);

   schedule _read  CF _read;

endmodule: mkIBUFDS

(* always_ready, always_enabled *)
interface IbufdsTest;
   (* prefix="" *)	  
   method Action in(Bit#(1) i, Bit#(1) ib);
   interface ReadOnly#(Bit#(1)) o;
endinterface

module mkIbufdsTest(IbufdsTest);
   Wire#(Bit#(1)) i_w <- mkDWire(0);
   Wire#(Bit#(1)) ib_w <- mkDWire(0);
   ReadOnly#(Bit#(1)) ibufds <- mkIBUFDS(i_w, ib_w);

   method Action in(Bit#(1) i, Bit#(1) ib);
       i_w <= i;
       ib_w <= ib;
   endmethod
   interface ReadOnly o = ibufds;
endmodule
