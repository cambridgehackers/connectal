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

import FIFOF::*;

/* This is a serial to parallel converter for messages of type a
 * The data register is assumed to always be available, so an arriving
 * message must be removed ASAP or be overwritten 
 */
interface SerialLinkOut;
   method bit frame(bit f);
   method bit data(bit d);
endinterface

interface LinkOut#(type a);
   interface SerialLinkOut link;
   interface FIFOF#(a) data;
endinterface



module mkLinkOut(LinkOut#(a))
       provisos(Bits#(a,asize)),
	        Log#(asize, k);

   // registers for sending data messages
   Reg#(bit) framebit <- mkReg(0);
   Reg#(bit) databit <- mkReg(0);
   
   Reg#(Bit#(k)) count <= mkReg(0);
   Reg#(a) shifter <- mkReg(0);
   FIFO#(a) datafifo <- mkSizedFIFOF(1);


   
   rule startshift;
      if (count == 0)
	 begin
            shifter <= datafifo.first >> 1;
	    datafifo.deq();
	    framebit <= 1;
	    databit <= datafifo.first[0];
	    count <= count + 1;
	 end
   endrule

   rule continueshift;
      if (count != 0)
	 begin
	    if (count == asize - 1)
	       begin
		  count <= 0;
		  framebit <= 0;
	       end
	    else
	       begin
		  count <= count + 1;
		  framebit <= 1;
		  databit <= shifter[0];
		  shifter <= shifter >> 1;
	       end
	 end
   endrule
   
   interface LinkOut;
   
      method bit frame();
         return framebit;
      endmethod
      
      method bit data();
         return databit;
      endmethod

      interface FIFO#(a) data = datafifo;
      
   endinterface

endmodule