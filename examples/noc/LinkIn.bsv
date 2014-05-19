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
interface LinkIn#(type a);
   method Action frame(bit f);
   method Action data(bit d);
   interface Reg#(Bool) dataready;
   interface ReadOnly#(a) ror;
endinterface


module mkLinkIn(LinkIn#(a))
       provisos(Bits#(a,asize)),
	        Log#(asize, k);

   // registers for receiving data messages
   Reg#(bit) framebit <- mkReg(0);
   Reg#(bit) databit <- mkReg(0);
   Reg#(Bit#(6)) incount <= mkReg(0);
   Reg#(a) shifter <- mkReg(0);
   Reg#(a) data <- mkReg(0);
   FIFOF#(?) <- mkSizedFIFOF(1);


   rule handleDataFrame;
      if (datainframebit == 0)
	 begin
            dataincount <= 0;
	 end
      else
	 dataincount <= dataincount + 1;
   endrule
   
   rule handleDataInShift (datainframebit == 1);
      Bit#(SizeOf(DataMessage)) tmp = datainshifter;
      tmp = tmp >> 1;
      tmp[SizeOf(DataMessage)-1] = datainbit;
      datainshifter <= tmp;
      if (dataincount == (SizeOf(DataMessage) - 1))
         action
	    new <= tmp;
	    dataready <= True;
	 end;
   endrule
   
   interface LinkIn;
   
      method Action frame(bit i );
	 frameinbit <= i ;
      endmethod
      
      method Action data( bit i );
	 datainbit <= i;
      endmethod

      interface ReadOnly#(a) ror = regToReadOnly(r);
      
      interface Reg#(Bool) ready = dataready;
   
   endinterface

endmodule