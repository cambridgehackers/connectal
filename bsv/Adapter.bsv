
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
import BRAMFIFO       ::*;
import FIFOF          ::*;

function Bit#(a) rtruncate(Bit#(b) x) provisos(Add#(k,a,b));
   match {.v,.*} = split(x);
   return v;
endfunction

interface ToBit32#(type a);
   method Bit#(32) depth32(); // size of a in 32-bit words
   method Bit#(32) count32(); // number of words in the adapter
   method Action enq(a v);          
   method Maybe#(Bit#(32)) first;
   method Action deq();
   method Bool notEmpty();
   method Bool notFull();
endinterface
   
interface FromBit32#(type a);
   method Bit#(32) depth32(); // size of a in 32-bit words
   method Bit#(32) count32(); // number of words in the adapter
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
   
   FIFOF#(Bit#(asz)) fifo <- mkSizedBRAMFIFOF(16);
   Reg#(Bit#(32))   count <- mkReg(0);


   method Bit#(32) depth32();
       return max+1;
   endmethod
   method Bit#(32) count32();
    return extend(max - count);
   endmethod

   method Action enq(a val) if (fifo.notFull);
      fifo.enq(pack(val));   
   endmethod

   method Maybe#(Bit#(32)) first();
    if (fifo.notEmpty)
       begin 
           let val = fifo.first();
           Bit#(asz32) vx = zeroExtend(val >> (32 * count));
           Bit#(32) x = vx[31:0];
           return tagged Valid x;
       end
    else
       begin
           return tagged Invalid;
       end
   endmethod
   method Action deq();
     if (fifo.notEmpty)
     begin
       if (count == max)
          begin 
             count <= 0;
             fifo.deq();
          end
       else
          begin
             count <= count + 1;
          end   
     end
   endmethod
               
   method Bool notEmpty = fifo.notEmpty;
   method Bool notFull = fifo.notFull;
endmodule

module mkFromBit32(FromBit32#(a))
   provisos(Bits#(a,asz),
            Add#(1,z,asz),
	    Add#(32,asz,asz32));

   Bit#(32) size   = fromInteger(valueOf(asz));
   Bit#(5)  offset = size[4:0];
   Bit#(32) max    = ((size + 31) >> 5) - 1;
   
   FIFOF#(Bit#(asz))  fifo <- mkSizedBRAMFIFOF(16);
   Reg#(Bit#(asz))    buff <- mkReg(0);
   Reg#(Bit#(32))    count <- mkReg(0);   
   
   method Bit#(32) depth32();
       return max+1;
   endmethod
   method Bit#(32) count32();
    return extend(count);
   endmethod

   method Action enq(Bit#(32) x) if (fifo.notFull);
      Bit#(asz32) concatedvalue = {x,buff};
      Bit#(asz) newval = rtruncate(concatedvalue);
      if (count == max)
         begin 
            count <= 0;
            buff  <= ?;
            Bit#(asz) longval = truncate({x,buff} >> ((offset==0) ? 32'd32 : zeroExtend(offset)));
            fifo.enq(longval);
         end
      else
         begin
            count <= count+1;
            buff  <= newval; 
         end
   endmethod
   
   method a first if (fifo.notEmpty());
       return unpack(fifo.first);
   endmethod

   method Action deq if (fifo.notEmpty());
       fifo.deq;
   endmethod
   
   method Bool notEmpty() = fifo.notEmpty;
   method Bool notFull() = fifo.notFull;
endmodule

interface ToBit64#(type a);
   method Action enq(a v);          
   method Bit#(64) first;
   method Action deq();
   method Bool notEmpty();
   method Bool notFull();
endinterface
   
interface FromBit64#(type a);
   method Action enq(Bit#(64) v);
   method a first();
   method Action deq();
   method Bool notEmpty();
   method Bool notFull();
endinterface

module mkToBit64(ToBit64#(a))
   provisos(Bits#(a,asz),
            Add#(1,z,asz),
	    Add#(64,asz,asz64));
   
   Bit#(64) size = fromInteger(valueOf(asz));
   Bit#(64) max  = (size >> 6) + ((size[5:0] == 0) ? 0 : 1)-1;
   
   FIFOF#(Bit#(asz))   fifo <- mkSizedBRAMFIFOF(16);
   Reg#(Bit#(64))     count <- mkReg(0);

   method Action enq(a val) if (fifo.notFull);
      fifo.enq(pack(val));   
   endmethod

   method Bit#(64) first();
    if (fifo.notEmpty)
       begin 
           let val = fifo.first();
           Bit#(asz64) vx = zeroExtend(val >> (64 * count));
           Bit#(64) x = vx[63:0];
           return x;
       end
    else
       begin
           return 0;
       end
   endmethod
   method Action deq();
     if (fifo.notEmpty)
     begin
       if (count == max)
          begin 
             count <= 0;
             fifo.deq();
          end
       else
          begin
             count <= count + 1;
          end   
     end
   endmethod
               
   method Bool notEmpty = fifo.notEmpty;
   method Bool notFull = fifo.notFull;
endmodule

module mkFromBit64(FromBit64#(a))
   provisos(Bits#(a,asz),
            Add#(1,zzz,asz),
	    Add#(64,asz,asz64));

   Bit#(64) size   = fromInteger(valueOf(asz));
   Bit#(6)  offset = size[5:0];
   Bit#(64) max    = (size >> 6) + ((offset == 0) ? 0 : 1) -1;
   
   FIFOF#(Bit#(asz))  fifo <- mkSizedBRAMFIFOF(16);
   Reg#(Bit#(asz))    buff <- mkReg(0);
   Reg#(Bit#(64))    count <- mkReg(0);   
   
   method Action enq(Bit#(64) x) if (fifo.notFull);
      Bit#(asz64) concatedvalue = {x,buff};
      Bit#(asz) newval = rtruncate(concatedvalue);
      if (count == max)
         begin 
            count <= 0;
            buff  <= ?;
            Bit#(asz) longval = truncate({x,buff} >> ((offset==0) ? 64'd32 : zeroExtend(offset)));
            fifo.enq(longval);
         end
      else
         begin
            count <= count+1;
            buff  <= newval; 
         end
   endmethod
   
   method a first if (fifo.notEmpty());
       return unpack(fifo.first);
   endmethod

   method Action deq if (fifo.notEmpty());
       fifo.deq;
   endmethod
   
   method Bool notEmpty() = fifo.notEmpty;
   method Bool notFull() = fifo.notFull;
endmodule
