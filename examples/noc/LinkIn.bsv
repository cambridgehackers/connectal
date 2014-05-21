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

/* This is a serial to parallel converter for messages of type a
 * The data register is assumed to always be available, so an arriving
 * message must be removed ASAP or be overwritten 
 */

interface SerialLinkIn;
   method Action frame(bit f);
   method Action data(bit d);
endinterface

interface LinkIn#(type a);
   interface SerialLinkIn link;
   interface Reg#(Bool) dataready;
   interface ReadOnly#(a) ror;
endinterface


module mkLinkIn(LinkIn#(a))
       provisos(Bits#(a,asize),
	        Log#(asize, k));

   // registers for receiving data messages
   Reg#(bit) framebit <- mkReg(0);
   Reg#(bit) databit <- mkReg(0);
   Reg#(Bit#(k)) count <- mkReg(0);
   Reg#(a) shifter <- mkReg(?);
   Reg#(a) data <- mkReg(?);
   Reg#(Bool) drdy <- mkReg(False);

   rule handleDataFrame;
      if (framebit == 0)
	 begin
            count <= 0;
	 end
      else
	 count <= count + 1;
   endrule
   
   rule handleDataInShift (framebit == 1);
      Bit#(asize) tmp = pack(shifter);
      tmp = tmp >> 1;
      tmp[valueOf(asize)-1] = databit;
      shifter <= unpack(tmp);
      if (count == fromInteger(valueof(asize) - 1))
         action
	    data <= unpack(tmp);
	    drdy <= True;
	 endaction
   endrule
   
   interface SerialLinkIn link;
   
      method Action frame(bit i );
	 framebit <= i ;
      endmethod
      
      method Action data( bit i );
	 databit <= i;
      endmethod

   endinterface

   interface ReadOnly ror = regToReadOnly(data);
      
   interface Reg dataready = drdy;
   

endmodule