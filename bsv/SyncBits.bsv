
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

import Vector::*;
import Clocks::*;

module mkSyncBits#(Clock sClkIn, Reset sRst, Clock dClkIn)(SyncBitIfc#(a))
   provisos (Bits#(a,awidth));
   Vector#(awidth, SyncBitIfc#(Bit#(1))) bits <- replicateM(mkSyncBit(sClkIn, sRst, dClkIn));

   method a read();
      function Bit#(1) readBit(SyncBitIfc#(Bit#(1)) syncBit); return syncBit.read(); endfunction
      return unpack(pack(map(readBit, bits)));
   endmethod: read
   method Action send(a value);
      Bit#(awidth) abits = pack(value);
      for (Integer i = 0; i < valueOf(awidth); i = i + 1) begin
	 bits[i].send(abits[i]);
      end
   endmethod: send
endmodule

module mkSyncBitsFromCC#(Clock dClkIn)(SyncBitIfc#(a))
   provisos (Bits#(a,awidth));
   Clock sClkIn <- exposeCurrentClock();
   Reset sRst <- exposeCurrentReset();
   SyncBitIfc#(a) syncbits <- mkSyncBits(sClkIn, sRst, dClkIn);
   return syncbits;
endmodule

module mkSyncBitsToCC#(Clock sClkIn, Reset sRst)(SyncBitIfc#(a))
   provisos (Bits#(a,awidth));
   Clock dClkIn <- exposeCurrentClock();
   SyncBitIfc#(a) syncbits <- mkSyncBits(sClkIn, sRst, dClkIn);
   return syncbits;
endmodule
