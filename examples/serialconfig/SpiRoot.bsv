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

import FIFO::*;
import SpiTap::*;

typedef struct {
   Bit#(32) a;
   Bit#(32) d;
   } SpiItem deriving(Bits);

module mkSpiRoot#(SpiTap root)(FIFO#(SpiItem));
   FIFO#(SpiItem) request <- mkSizedFIFO(8);
   FIFO#(SpiItem) response <- mkSizedFIFO(8);

   Reg#(Bit#(6)) countin <- mkReg(0);   /* overflow at 63 -> 0 */
   Reg#(Bit#(6)) countout <- mkReg(0);
   Reg#(Bit#(64)) shifter <- mkReg(0);
   Wire#(bit) framedrive <- mkDWire(0);
   
   /* implicit dependence on request fifo not empty */
   rule send_item;
      if (countin < 32)
	 begin
	    root.in.data(request.first.a[countin&31]);
	    framedrive <= 1;
	    countin <= countin + 1;
	 end
      else
	 begin
	    root.in.data(request.first.d[countin&31]);
	    framedrive <= 1;
	    countin <= countin + 1;
	 end
      if (countin == 63)
	 request.deq();
      endrule
   
   rule genframe;
      root.in.frame(framedrive);
   endrule
   
   rule handleFrame;
      Bit#(64) tmp;
      if (root.out.frame() == 0)
	 begin
	    tmp = 0;
	    countout <= 0;
	 end
      else
	 begin
	    countout <= countout + 1;
	    tmp = shifter;
	    tmp = tmp >> 1;
	    tmp[63] = root.out.data();
	    shifter <= tmp;
	 end
      if (countout == 63)
	    response.enq(SpiItem{a: tmp[31:0], d: tmp[63:32]});
   endrule
   // method Action enq = request.enq;
   
   
   method Action enq(SpiItem x);
      request.enq(x);
   endmethod
   
   method Action deq();
      response.deq();
   endmethod
   
   method SpiItem first();
      return response.first();
   endmethod
   
   method Action clear();
      request.clear();
      response.clear();
      countout <= 0;
   endmethod

endmodule

