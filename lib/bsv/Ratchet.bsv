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

import GetPut::*;

interface Ratchet#(numeric type count_sz);
   method Action decrement(UInt#(count_sz) x);
   method Action increment(UInt#(count_sz) x);
   method UInt#(count_sz) read();
endinterface

module mkRatchet#(UInt#(count_sz) init_val)(Ratchet#(count_sz));
   Wire#(UInt#(count_sz)) inc_wire <- mkDWire(0);
   Wire#(UInt#(count_sz)) dec_wire <- mkDWire(0);
   Reg#(UInt#(count_sz)) cnt <- mkReg(init_val);
   (* fire_when_enabled *)
   rule react;
      if (inc_wire > dec_wire)
	 cnt <= satPlus(Sat_Bound, cnt, (inc_wire - dec_wire));
      else
	 cnt <= satMinus(Sat_Bound, cnt, (dec_wire - inc_wire));
   endrule
   method Action increment(UInt#(count_sz) x);
      inc_wire <= x;
   endmethod
   method Action decrement(UInt#(count_sz) x);
      dec_wire <= x;
   endmethod
   method UInt#(count_sz) read = cnt._read;
endmodule
