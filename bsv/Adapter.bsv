
// Copyright (c) 2012 MIT
// Copyright (c) 2012 Nokia, Inc.

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

import GetPut         ::*;
import FIFOF          ::*;
import SpecialFIFOs   ::*;

function Bit#(a) rtruncate(Bit#(b) x) provisos(Add#(k,a,b));
   match {.v,.*} = split(x);
   return v;
endfunction

interface ToBit32#(type a);
   method Action enq(a v);          
   method Bit#(32) first;
   method Action deq();
   method Bool notEmpty();
   method Bool notFull();
endinterface
   
interface FromBit32#(type a);
   method Action enq(Bit#(32) v);
   method a first();
   method Action deq();
   method Bool notEmpty();
   method Bool notFull();
endinterface

module mkToBit32(ToBit32#(a))
   provisos(Bits#(a,asz),
            Add#(1, z, asz),
	    Add#(32,asz,asz32));
   
   Bit#(32) size = fromInteger(valueOf(asz));
   Bit#(32) max  = ((size + 31) >> 5) - 1;
   
   Reg#(Bool)       valid <- mkReg(False);
   Reg#(Bit#(asz32)) buff <- mkReg(0);
   Reg#(Bit#(32))   count <- mkReg(0);


   method Action enq(a val) if (!valid);
      buff <= {pack(val),32'b0};
      valid <= True;
   endmethod

   method Bit#(32) first() if (valid);
      return rtruncate(buff);
   endmethod

   method Action deq() if (valid);
      if (count == max)
         begin 
            count <= 0;
            valid <= False;
         end
      else
         begin
            count <= count + 1;
	    buff <= buff << 32;
         end   
   endmethod
   method Bool notEmpty = valid;
   method Bool notFull = !valid;
endmodule

module mkFromBit32(FromBit32#(a))
   provisos(Bits#(a,asz),
            Add#(1,z,asz),
	    Add#(32,asz,asz32));

   Bit#(32) size   = fromInteger(valueOf(asz));
   Bit#(32) max    = ((size + 31) >> 5) - 1;
   
   Reg#(Bool)        valid <- mkReg(False);
   Reg#(Bit#(asz))    buff <- mkReg(0);
   Reg#(Bit#(32))    count <- mkReg(0);   
   
   method Action enq(Bit#(32) x) if (!valid);
      Bit#(asz32) concatedvalue = {buff,x};
      buff  <= truncate(concatedvalue);
      if (count == max)
         begin 
            count <= 0;
	    valid <= True;
         end
      else
         begin
            count <= count+1;
         end
   endmethod
   
   method a first if (valid);
       return unpack(buff);
   endmethod

   method Action deq if (valid);
       valid <= False;
   endmethod
   
   method Bool notEmpty() = valid;
   method Bool notFull() = !valid;
endmodule

