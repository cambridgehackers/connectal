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

import RegC::*;
import Connectable::*;

/* This is a simple serial bus
 * The frame bit indicates the valid period of a message
 * 
 */

interface SpiTapIn;
   method Action framein(bit f);
   method Action datain(bit d);
endinterface

interface SpiTapOut;
   method bit frameout();
   method bit dataout();
endinterface

interface SpiTap;
   interface SpiTapIn in;
   interface SpiTapOut out;
endinterface

instance Connectable#(SpiTapOut, SpiTapIn);
   module mkConnection#(SpiTapOut out, SpiTapIn in)(Empty);
      rule move_data;
	 in.framein(out.frameout());
	 in.datain(out.dataout());
	 endrule
   endmodule
endinstance

module mkSpiTap#(Bit#(32) id)(SpiTap);
   Reg#(bit) frameinbit <- mkReg(0);
   Reg#(bit) datainbit <- mkReg(0);
   
   Reg#(Bit#(6)) count <- mkReg(0);
   Reg#(Bit#(32)) shifter <- mkReg(0);
   Reg#(Bit#(32)) address <- mkReg(0);
   Reg#(Bit#(32)) data <- mkReg(0);
   
   rule handleFrame;
      if (frameinbit == 0)
	 count <= 0;
      else
	 count <= count + 1;
   endrule
   
   rule handleShift (frameinbit == 1);
      Bit#(32) tmp = shifter;
      tmp = tmp >> 1;
      tmp[31] = datainwire;
      shifter <= tmp;
      if (count == 31) 
	 address <= tmp;
      if ((count == 63) && (address == id))
	 data <= tmp;
   endrule

   interface SpiTapIn in;
   
      method Action framein(bit i );
	 frameinbit <= i ;
      endmethod

      method Action datain( bit i );
	 datainbit <= i;
      endmethod

   endinterface
   
   interface SpiTapOut out;
   
      method bit frameout();
	 return frameinbit;
      endmethod
   
      method bit dataout();
         bit tmp;
         if ((count < 32) || (address[31:1] != id[31:1]) || (address[0] == 0))
	    tmp = datainbit;
	 else
	    tmp = (data[count & 31]);
         return tmp;
      endmethod

   endinterface

endmodule

