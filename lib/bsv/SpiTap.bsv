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

import Connectable::*;

/* This is a simple serial bus
 * The frame bit indicates the valid period of a message
 * 
 */

interface SpiTapIn;
   method Action frame(bit f);
   method Action data(bit d);
endinterface

interface SpiTapOut;
   method bit frame();
   method bit data();
endinterface

interface SpiTap;
   interface SpiTapIn in;
   interface SpiTapOut out;
endinterface

interface SpiReg#(type a);
   interface SpiTap tap;
   interface Reg#(a) r;
endinterface

instance Connectable#(SpiTapOut, SpiTapIn);
   module mkConnection#(SpiTapOut out, SpiTapIn in)(Empty);
      rule move_data;
	 in.frame(out.frame());
	 in.data(out.data());
	 endrule
   endmodule
endinstance

module mkSpiReg#(Bit#(32) id)(SpiReg#(a))
   provisos(Bits#(a,asize),
      Add#(a__, asize, 32));
   Reg#(bit) frameinbit <- mkReg(0);
   Reg#(bit) datainbit <- mkReg(0);
   Wire#(bit) dataoutwire <- mkDWire(0);
   
   Reg#(Bit#(6)) count <- mkReg(0);
   Reg#(Bit#(32)) shifter <- mkReg(0);
   Reg#(Bool) addressmatch <- mkReg(False);
   Reg#(Bool) iswrite <- mkReg(False);
   Reg#(Bit#(asize)) data <- mkReg(0);
   
   rule handleFrame (frameinbit == 0);
      count <= 0;
      addressmatch <= False;
   endrule
   
   rule handleShift (frameinbit == 1);
      Bit#(32) tmp = shifter;
      tmp = tmp >> 1;
      tmp[31] = datainbit;
      shifter <= tmp;
      if (count == 31) 
	 begin
	    iswrite <= tmp[0] == 1;
            addressmatch <= (id[31:1] == tmp[31:1]);
         end
      if ((count == 63) && addressmatch && iswrite)
	 data <= truncate(tmp);
      if ((count[5] == 1) && addressmatch && (!iswrite))
          begin
	     if (valueof(asize) == 32)
		dataoutwire <= data[count & 31];
	     else
		begin
		   if ((count & 31) < fromInteger(valueof(asize)))
                      dataoutwire <= data[count & 31];
		end
	  end
      else
	 dataoutwire <= datainbit;
      count <= count + 1;
   endrule

   interface SpiTap tap;
   
      interface SpiTapIn in;
   
	 method Action frame(bit i );
	    frameinbit <= i ;
	 endmethod
   
	 method Action data( bit i );
	    datainbit <= i;
	 endmethod

      endinterface
   
      interface SpiTapOut out;
      
	 method bit frame();
	    return frameinbit;
	 endmethod
      
	 method bit data();
	    return dataoutwire;
	 endmethod
   
      endinterface
   
   endinterface

   interface Reg r;

      method Action _write(a v);
	 data <= pack(v);
      endmethod
   
      method a _read();
	 return(unpack(data));
      endmethod

   endinterface

endmodule

